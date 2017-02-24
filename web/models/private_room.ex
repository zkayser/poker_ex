defmodule PokerEx.PrivateRoom do
  use PokerEx.Web, :model
  require Logger
  alias PokerEx.Player
  alias PokerEx.PrivateRoom
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
                  on_delete: :delete_all
    many_to_many :invitees, 
                  PokerEx.Player, 
                  join_through: "invitees_private_rooms", 
                  join_keys: [private_room_id: :id, invitee_id: :id],
                  on_replace: :delete
    timestamps()
  end
  
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
  
  def store_state(%PrivateRoom{title: _id} = priv_room, %{"room_state" => state, "room_data" => room}) do
    # Todo, if saving fails, delete the private room and return chips to players.
    update =
      priv_room
      |> cast(%{room_data: room, room_state: state}, [:room_data, :room_state])
    
    case Repo.update(update) do
      {:ok, _} -> :ok
      _ -> :error
    end
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
  
  def put_invitee_in_participants(changeset, participants, invitee) do
    participants = participants ++ [invitee]
    IO.puts "put_invitee_in_participants called with: #{inspect(participants)}"
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
        x when is_pid(pid) ->
          Logger.info "Shutting down room: #{room.title}"
          Supervisor.terminate_child(RoomsSupervisor, pid)
        _ ->
          Logger.debug "An unknown error occurred in shutdown_all function - room.title, pid: #{room.title}, #{inspect(pid)}"
      end 
    end
  end
end