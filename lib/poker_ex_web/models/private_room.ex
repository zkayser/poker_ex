defmodule PokerEx.PrivateRoom do
  use PokerExWeb, :model
  require Logger
  alias PokerEx.{Player, Repo, Notifications, PrivateRoom}
  alias PokerEx.GameEngine.GamesSupervisor
  alias PokerEx.GameEngine, as: Game

  schema "private_games" do
    field(:title, :string)
    field(:room_data, :binary)
    field(:room_state, :binary)
    field(:stored_game_data, :binary)
    belongs_to(:owner, PokerEx.Player)

    many_to_many(
      :participants,
      PokerEx.Player,
      join_through: "participants_private_rooms",
      join_keys: [private_room_id: :id, participant_id: :id],
      on_delete: :delete_all,
      on_replace: :delete
    )

    many_to_many(
      :invitees,
      PokerEx.Player,
      join_through: "invitees_private_rooms",
      join_keys: [private_room_id: :id, invitee_id: :id],
      on_replace: :delete
    )

    timestamps()
  end

  @type t :: %__MODULE__{
          title: String.t(),
          room_data: any(),
          room_state: any(),
          owner: Player.t(),
          participants: list(Player.t()),
          invitees: list(Player.t())
        }

  @doc ~S"""
  `create/3` is a high-level function for creating a new private room. It takes a title,
  owner (a `Player` struct), and a list of invitees (also `Player` structs). It will return :ok
  and the `PrivateRoom` instance in a tuple if valid. The room instance will also be committed
  to the database and the `PokerEx.Room` `:gen_statem` instance will also be initiated.
  """
  @spec create(String.t(), Player.t(), list(Player.t())) ::
          {:ok, __MODULE__.t()} | {:error, maybe_improper_list(atom(), {String.t(), any()})}
  def create(title, %Player{} = owner, invitees) do
    with {:ok, %__MODULE__{} = room} <-
           %__MODULE__{title: format_title(title), owner: owner, invitees: invitees}
           |> changeset()
           |> update_participants([owner])
           |> Repo.insert() do
      case GamesSupervisor.create_private_game(format_title(title)) do
        {:ok, _} ->
          Notifications.notify_invitees(room)
          {:ok, room}

        {:error, error} ->
          {:error, error}
      end
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
  @spec accept_invitation(__MODULE__.t(), Player.t()) ::
          {:ok, __MODULE__.t()} | {:error, Ecto.Changeset.t()}
  def accept_invitation(%__MODULE__{} = room, %Player{} = participant) do
    room = preload(room)

    room
    |> change()
    |> update_participants([participant | room.participants])
    |> update_invitees(Enum.reject(room.invitees, &(&1.id == participant.id)))
    |> Repo.update()
  end

  @doc ~S"""
  `decline_invitation/2` is used when a player declines an invitation to a private room, thus removing
  the player from the `PrivateRoom` instance's `invitees` list.
  """
  @spec decline_invitation(__MODULE__.t(), Player.t()) ::
          {:ok, __MODULE__.t()} | {:error, Ecto.Changeset.t()}
  def decline_invitation(%__MODULE__{} = room, %Player{} = declining_player) do
    room = preload(room)

    room
    |> change()
    |> update_invitees(Enum.reject(room.invitees, &(&1.id == declining_player.id)))
    |> Repo.update()
  end

  @doc ~S"""
  `leave_room/2` removes a player from the `participants` list and also from the ongoing
  `Room` instance if the player is among the players seated in the `room`.
  """
  @spec leave_room(__MODULE__.t(), Player.t()) ::
          {:ok, __MODULE__.t()} | {:error, Ecto.Changeset.t()}
  def leave_room(%__MODULE__{} = room, %Player{} = leaving_player) do
    room = preload(room)

    with {:ok, %__MODULE__{} = room} <-
           room
           |> change()
           |> update_participants(Enum.reject(room.participants, &(&1.id == leaving_player.id)))
           |> Repo.update() do
      Game.leave(room.title, leaving_player)
      {:ok, room}
    else
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc ~S"""
  `delete/1` removes the `PrivateRoom` instance from the database and stops the `Room` instance
  """
  @spec delete(__MODULE__.t()) :: {:ok, __MODULE__.t()} | {:error, String.t()}
  def delete(%__MODULE__{} = room) do
    with :ok <- Enum.each(preload(room).participants, &Game.leave(room.title, &1)),
         :ok <- Game.stop(room.title),
         invitees <- preload(room).invitees,
         participants <- preload(room).participants,
         owner <- preload(room).owner do
      {:ok, room} =
        room
        |> change()
        |> put_assoc(:participants, [])
        |> put_assoc(:invitees, [])
        |> Repo.update()

      Notifications.notify(
        [owner: owner, title: room.title, recipients: invitees ++ participants],
        :deletion
      )

      Repo.delete(room)
    else
      _ -> {:error, "Failed to shutdown room process"}
    end
  end

  @doc ~S"""
  Returns all `PrivateRoom` instances stored in the database
  """
  @spec all() :: list(__MODULE__.t())
  def all(), do: Repo.all(__MODULE__)

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:title])
    |> validate_length(:title, min: 1, max: 16)
    |> unique_constraint(:title, name: :private_rooms_title_index)
    |> unique_constraint(:title, name: :private_games_title_index)
  end

  @doc ~S"""
  Returns the `PrivateRoom` instance with the given id or `nil`
  """
  @spec get(pos_integer()) :: __MODULE__.t() | nil
  def get(id), do: Repo.get(__MODULE__, id)

  @doc ~S"""
  Returns the `PrivateRoom` instance with the given title or `nil`
  """
  @spec by_title(String.t()) :: __MODULE__.t() | nil
  def by_title(title), do: Repo.get_by(__MODULE__, title: title)

  @doc ~S"""
  Preloads the `PrivateRoom` instance passed in with `invitees`,
  `owner`, and `participants` associations
  """
  @spec preload(__MODULE__.t()) :: __MODULE__.t()
  def preload(private_room) do
    private_room |> Repo.preload([:invitees, :owner, :participants])
  end

  @doc ~S"""
  Checks to see if the process for the `Room` instance is alive and restores
  it from the database if not. Returns an empty `Room` instance if no data has
  been stored
  """
  @spec ensure_started(String.t()) :: Room.t()
  def ensure_started(game_process) when is_binary(game_process) do
    case GamesSupervisor.process_exists?(game_process) do
      false ->
        %{stored_game_data: game_data} = by_title(game_process)

        with {:ok, game_data} <- PokerEx.GameEngine.Impl.decode(game_data) do
          GamesSupervisor.create_private_game(game_process)
          put_state_for_game(game_process, game_data)
        else
          nil ->
            with {:ok, title} <- GamesSupervisor.create_private_game(game_process) do
              PokerEx.GameEngine.get_state(title)
            end

          error ->
            error
        end

      _ ->
        Game.get_state(game_process)
    end
  end

  @spec restart(String.t()) :: Room.t()
  def restart(title) do
    %{stored_game_data: game_data} = by_title(title)

    with {:ok, game_data} <- PokerEx.GameEngine.Impl.decode(game_data) do
      GamesSupervisor.create_private_game(title)
      put_state_for_game(title, game_data)
    end
  end

  @doc ~S"""
  Takes a string representing the title of a running game process that is also
  the title of a `PrivateRoom` instance stored in the database. The second parameter
  is an instance of the current game state. The function encodes the current game
  state into JSON for storage. This is useful when terminating a `Game` process in
  cases where the server encounters an error. Having the state of the current game
  stored in the DB means taht it can be recovered when the Game process is restarted,
  preventing players from losing their turns or forfeting chips that they had in play.
  """
  @spec get_game_and_store_state(String.t(), PokerEx.GameEngine.Impl.t()) :: {:ok, pid()}
  def get_game_and_store_state(title, game_data) when is_binary(title) do
    with {:ok, game_json} <- Jason.encode(game_data) do
      Task.start(fn ->
        Repo.get_by(PrivateRoom, title: title)
        |> store_state(%{"stored_game_data" => game_json})
      end)
    end
  end

  @doc ~S"""
  Takes in a player instance and a room title. Returns true if the player is the owner of
  the room, false otherwise.
  """
  @spec is_owner?(Player.t(), String.t()) :: boolean()
  def is_owner?(%Player{} = player, title) do
    owner =
      title
      |> by_title()
      |> preload()
      |> Map.get(:owner)

    owner.name == player.name
  end

  @spec alive?(String.t()) :: boolean()
  def alive?(title) when is_binary(title) do
    GamesSupervisor.process_exists?(title)
  end

  def alive?(title), do: {:error, {:invalid_title, title}}

  defp store_state(nil, _room_state) do
    Logger.error(
      "Failed to store state because room either does not exist or could not be found."
    )

    :error
  end

  defp store_state(%PrivateRoom{title: id} = priv_room, %{
         "room_state" => state,
         "room_data" => room
       }) do
    update =
      priv_room
      |> cast(%{room_data: room, room_state: state}, [:room_data, :room_state])

    case Repo.update(update) do
      {:ok, _} ->
        :ok

      _ ->
        Logger.error("Failed to store state for room #{inspect(id)}")
        :error
    end
  end

  defp store_state(%PrivateRoom{title: id} = priv_room, %{"stored_game_data" => game_data}) do
    priv_room
    |> cast(%{stored_game_data: game_data}, [:stored_game_data])
    |> Repo.update()
    |> case do
      {:ok, _} ->
        :ok

      _ ->
        Logger.error("Failed to store state for game: #{inspect(id)}")
        :error
    end
  end

  defp format_title(title) when is_binary(title) do
    String.replace(title, ~r(\s+), "_")
    |> String.replace("%20", "_")
  end

  defp format_title(_), do: {:error, :invalid_title}

  defp put_state_for_game(room_process, nil), do: Game.get_state(room_process)

  defp put_state_for_game(room_process, data) do
    Logger.info("Restoring game data for room: #{inspect(room_process)}")
    Game.put_state(room_process, data)
  end

  def update_participants(changeset, participants) do
    put_assoc(changeset, :participants, participants)
  end

  def update_invitees(changeset, invitees) do
    put_assoc(changeset, :invitees, invitees)
  end
end
