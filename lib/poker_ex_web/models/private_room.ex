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
    with {:ok, %__MODULE__{} = room} <- %__MODULE__{title: title, owner: owner, invitees: invitees}
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
      Room.leave(String.to_atom(room.title), leaving_player)
      {:ok, room}
    else
      {:error, changeset} -> {:error, changeset}
    end
  end

  ################################################################################
  #         BELOW IS THE OLD VERSION OF THIS MODULE THAT WILL BE PHASED OUT      #
  ################################################################################

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, ~w(title))
    |> validate_length(:title, min: 1, max: 16)
    |> unique_constraint(:title)
  end

  def create_changeset(model, %{"owner" => _owner} = params) do
    model
    |> changeset(params)
    |> cast_assoc(:owner, required: true)
  end

  def update_changeset(model, %{"participants" => _participants, "invitees" => _invitees} = params) do
    model
    |> changeset(params)
    |> cast_assoc(:participants)
    |> cast_assoc(:invitees)
  end

  # def move_invitee_to_participants(private_room, player) do
  #   changeset =
  #     private_room
  #     |> changeset()
  #     |> remove_invitee(private_room.invitees, player)
  #     |> put_invitee_in_participants(private_room.participants, player)
  #   Repo.update(changeset)
  # end

  def get_room_and_store_state(title, state, room) when is_atom(title) do
    title = Atom.to_string(title)
    state = :erlang.term_to_binary(state)
    room = :erlang.term_to_binary(room)
    Task.start(
      fn ->
        Repo.get_by(PrivateRoom, title: title)
        |> store_state(%{"room_state" => state, "room_data" => room})
      end)
  end

  def store_state(nil, _room_state) do
    require Logger
    Logger.error "\nFailed to store state because room either does not exist or could not be found."
  end

  def store_state(%PrivateRoom{title: id} = priv_room, %{"room_state" => state, "room_data" => room}) do
    require Logger
    update =
      priv_room
      |> cast(%{room_data: room, room_state: state}, [:room_data, :room_state])

    case Repo.update(update) do
      {:ok, _} -> :ok
      _ ->
        Logger.warn "Could not successfully update room: #{id}"
        :error
    end
  end

  def stop_and_delete(%PrivateRoom{title: title} = priv_room) do
    title = String.to_atom(title)
    if RoomsSupervisor.room_process_exists?(title), do: :gen_statem.stop(title)
    delete(priv_room)
  end

  def delete(priv_room) do
    {:ok, priv_room} =
      priv_room
      |> preload
      |> cast(%{}, ~w())
      |> put_assoc(:participants, [])
      |> put_assoc(:invitees, [])
      |> Repo.update
     Repo.delete(priv_room)
  end

  def preload(private_room) do
    private_room |> Repo.preload([:invitees, :owner, :participants])
  end

  def put_owner(changeset, owner) do
    case Repo.get(Player, String.to_integer(owner)) do
      nil -> add_error(changeset, :owner, "invalid owner")
      player ->
        changeset
        |> put_assoc(:owner, player)
    end
  end

  def put_invitees(changeset, invitees) when is_list(invitees) do
    invitees =
      Enum.map(invitees, &String.to_integer/1)
      |> Enum.map(&(Repo.get(Player, &1)))
      |> Enum.reject(&(&1 == nil))
    changeset
    |> put_assoc(:invitees, invitees)
  end

  def remove_invitee(changeset, invitees, invitee) do
    invitees = Enum.reject(invitees, fn inv -> inv.id == invitee.id end)
    put_assoc(changeset, :invitees, invitees)
  end

  def remove_invitee(private_room, invitee) do
    private_room
      |> preload()
      |> changeset()
      |> put_assoc(:invitees, Enum.reject((private_room |> Repo.preload(:invitees)).invitees, fn inv -> inv.id == invitee.id end))
      |> Repo.update()
  end

  def update_participants(changeset, participants) do
    put_assoc(changeset, :participants, participants)
  end

  def update_invitees(changeset, invitees) do
    put_assoc(changeset, :invitees, invitees)
  end

  # Just totally broke this; Don't try to use this right now. Instead use `update_participants/2`
  def add_participant(changeset, participants) do
    put_assoc(changeset, :participants, participants)
  end

  def remove_participant(changeset, participants, participant) do
    participants = participants -- [participant]
    put_assoc(changeset, :participants, participants)
  end

  def shutdown_all do
    alias PokerEx.RoomsSupervisor
    rooms = Repo.all(PrivateRoom)
    for room <- rooms do
      pid =
        room.title
        |> String.to_atom
        |> Process.whereis
      case pid do
        nil ->
          Logger.info "No running process for #{room.title}\nDeleting #{room.title}"
          Repo.delete(room)
        _ when is_pid(pid) ->
          Logger.info "Shutting down room: #{room.title}"
          Supervisor.terminate_child(RoomsSupervisor, pid)
        _ ->
          Logger.debug "An unknown error occurred in shutdown_all function - room.title, pid: #{room.title}, #{inspect(pid)}"
      end
    end
  end
end
