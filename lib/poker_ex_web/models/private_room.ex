defmodule PokerEx.PrivateRoom do
  use PokerExWeb, :model
  require Logger
  alias PokerEx.Player
  alias PokerEx.PrivateRoom
  alias PokerEx.Room
  alias PokerEx.RoomsSupervisor
  alias PokerEx.Repo

  schema "private_rooms" do
    field :title, :string
    field :room_data, :binary
    field :room_state, :binary
    belongs_to :owner, PokerEx.Player
    many_to_many :participants,
                  PokerEx.Player,
                  join_through: "participants_private_rooms",
                  join_keys: [private_room_id: :id, participant_id: :id],
                  on_delete: :delete_all,
                  on_replace: :delete
    many_to_many :invitees,
                  PokerEx.Player,
                  join_through: "invitees_private_rooms",
                  join_keys: [private_room_id: :id, invitee_id: :id],
                  on_replace: :delete
    timestamps()
  end

  @type t :: %__MODULE__{title: String.t, room_data: any(), room_state: any(),
                      owner: Player.t, participants: list(Player.t), invitees: list(Player.t)}

  @doc ~S"""
  `create/3` is a high-level function for creating a new private room. It takes a title,
  owner (a `Player` struct), and a list of invitees (also `Player` structs). It will return :ok
  and the `PrivateRoom` instance in a tuple if valid. The room instance will also be committed
  to the database and the `PokerEx.Room` `:gen_statem` instance will also be initiated.
  """
  @spec create(String.t, Player.t, list(Player.t))  :: {:ok, __MODULE__.t} | {:error, maybe_improper_list(atom(), {String.t, any()})}
  def create(title, %Player{} = owner, invitees) do
    with {:ok, %__MODULE__{} = room} <- %__MODULE__{title: format_title(title), owner: owner, invitees: invitees}
        |> changeset()
        |> update_participants([owner])
        |> Repo.insert() do
      RoomsSupervisor.create_private_room(title)
      {:ok, room}
    else
      {:error, changeset} -> {:error, changeset.errors}
    end
  end

  @doc ~S"""
  `accept_invitation/2` is meant to be used when a player who has been invited to a room accepts
  the invitation. This will remove the player from the `PrivateRoom` instance's `invitee` list and
  move the player into the instance's `participants` list. The function also takes care of the
  associations on the other side, i.e., puts the `PrivateRoom` instance into the `participating_rooms`
  list on the `Player` instance and remove the room from the player's `invited_rooms`.
  """
  @spec accept_invitation(__MODULE__.t, Player.t) :: {:ok, __MODULE__.t} | {:error, Ecto.Changeset.t}
  def accept_invitation(%__MODULE__{} = room, %Player{} = participant) do
    room = preload(room)
    room
    |> change()
    |> update_participants([participant | room.participants])
    |> update_invitees(Enum.reject(room.invitees, &(&1.id == participant.id)))
    |> Repo.update
  end

  @doc ~S"""
  `decline_invitation/2` is used when a player declines an invitation to a private room, thus removing
  the player from the `PrivateRoom` instance's `invitees` list.
  """
  @spec decline_invitation(__MODULE__.t, Player.t) :: {:ok, __MODULE__.t} | {:error, Ecto.Changeset.t}
  def decline_invitation(%__MODULE__{} = room, %Player{} = declining_player) do
    room = preload(room)
    room
      |> change()
      |> update_invitees(Enum.reject(room.invitees, &(&1.id == declining_player.id)))
      |> Repo.update
  end

  @doc ~S"""
  `leave_room/2` removes a player from the `participants` list and also from the ongoing
  `Room` instance if the player is among the players seated in the `room`.
  """
  @spec leave_room(__MODULE__.t, Player.t) :: {:ok, __MODULE__.t} | {:error, Ecto.Changeset.t}
  def leave_room(%__MODULE__{} = room, %Player{} = leaving_player) do
    room = preload(room)
    with {:ok, %__MODULE__{} = room} <-
      room
        |> change()
        |> update_participants(Enum.reject(room.participants, &(&1.id == leaving_player.id)))
        |> Repo.update() do
      Room.leave(room.title, leaving_player)
      {:ok, room}
    else
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc ~S"""
  `delete/1` removes the `PrivateRoom` instance from the database and stops the `Room` instance
  """
  @spec delete(__MODULE__.t) :: {:ok, __MODULE__.t} | {:error, String.t}
  def delete(%__MODULE__{} = room) do
    with :ok <- Enum.each(preload(room).participants, &(Room.leave(room.title, &1))),
         :ok <- Room.stop(room.title) do
      {:ok, room} =
        room
          |> change()
          |> put_assoc(:participants, [])
          |> put_assoc(:invitees, [])
          |> Repo.update()
      Repo.delete(room)
    else
      _ -> {:error, "Failed to shutdown room process"}
    end
  end

  @doc ~S"""
  Returns all `PrivateRoom` instances stored in the database
  """
  @spec all() :: list(__MODULE__.t)
  def all(), do: Repo.all(__MODULE__)

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, ~w(title))
    |> validate_length(:title, min: 1, max: 16)
    |> unique_constraint(:title)
  end

  @doc ~S"""
  Returns the `PrivateRoom` instance with the given id or `nil`
  """
  @spec get(pos_integer()) :: __MODULE__.t | nil
  def get(id), do: Repo.get(__MODULE__, id)

  @doc ~S"""
  Returns the `PrivateRoom` instance with the given title or `nil`
  """
  @spec by_title(String.t) :: __MODULE__.t | nil
  def by_title(title), do: Repo.get_by(__MODULE__, title: title)

  @doc ~S"""
  Preloads the `PrivateRoom` instance passed in with `invitees`,
  `owner`, and `participants` associations
  """
  @spec preload(__MODULE__.t) :: __MODULE__.t
  def preload(private_room) do
    private_room |> Repo.preload([:invitees, :owner, :participants])
  end

  @doc ~S"""
  Checks to see if the process for the `Room` instance is alive and restores
  it from the database if not. Returns an empty `Room` instance if no data has
  been stored
  """
  @spec check_state(String.t) :: Room.t
  def check_state(room_process) when is_binary(room_process) do
    case RoomsSupervisor.room_process_exists?(room_process) do
      false ->
        %{room_state: room_state, room_data: room_data} = by_title(room_process)
        RoomsSupervisor.create_private_room(room_process)
        put_state_for_room(room_process, room_state, room_data)
      _ -> Room.state(room_process)
    end
  end

  @doc ~S"""
  Takes in an string that represents a running room process that is also the title
  of a `PrivateRoom` instance stored in the database. The second parameter is the
  current `state` of the `Room` process, i.e. :idle, :pre_flop, :flop, :turn, :river,
  or :between_hands, and the third parameter is the actual `Room` instance representing
  the ongoing game of Poker. This function queries the database for the `PrivateRoom`
  instance from the title and serializes the `state` and `room` as binaries to be
  stored in the database. This is useful when terminating a `Room` process when, for
  example, an error is encountered on the server. Having the state of the current game
  stored in the DB means that it can be recovered when the Room process is started
  back up again so that players do not lose their turns or forfeit chips that they
  already had in play.
  """
  @spec get_room_and_store_state(String.t, atom(), Room.t) :: {:ok, pid()}
  def get_room_and_store_state(title, state, room) when is_binary(title) do
    state = :erlang.term_to_binary(state)
    room = :erlang.term_to_binary(room)
    Task.start(
      fn ->
        Repo.get_by(PrivateRoom, title: title)
        |> store_state(%{"room_state" => state, "room_data" => room})
      end)
  end

  @spec alive?(String.t) :: boolean()
  def alive?(title) when is_binary(title) do
    RoomsSupervisor.room_process_exists?(title)
  end
  def alive?(title), do: {:error, {:invalid_title, title}}

  defp store_state(nil, _room_state) do
    Logger.error "Failed to store state because room either does not exist or could not be found."
    :error
  end

  defp store_state(%PrivateRoom{title: id} = priv_room, %{"room_state" => state, "room_data" => room}) do
    update =
      priv_room
      |> cast(%{room_data: room, room_state: state}, [:room_data, :room_state])

    case Repo.update(update) do
      {:ok, _} -> :ok
      _ ->
        Logger.error "Failed to store state for room #{inspect id}"
        :error
    end
  end

  defp format_title(title) when is_binary(title) do
    String.replace(title, ~r(\s+), "_")
  end
  defp format_title(_), do: {:error, :invalid_title}

  defp put_state_for_room(room_process, nil, nil), do: Room.state(room_process)
  defp put_state_for_room(room_process, state, data) do
    Room.put_state(room_process, :erlang.binary_to_term(state), :erlang.binary_to_term(data))
  end

  def update_participants(changeset, participants) do
    put_assoc(changeset, :participants, participants)
  end

  def update_invitees(changeset, invitees) do
    put_assoc(changeset, :invitees, invitees)
  end
end
