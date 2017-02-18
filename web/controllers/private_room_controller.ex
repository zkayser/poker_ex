defmodule PokerEx.PrivateRoomController do
  use PokerEx.Web, :controller
  alias PokerEx.PrivateRoom
  
  def new(conn, _params) do
    changeset = PrivateRoom.changeset(%PrivateRoom{invitees: [], owner: nil}, %{})
    query = 
      from p in PokerEx.Player,
        where: p.id != ^conn.assigns[:current_player].id,
        limit: 25,
        order_by: [asc: :id],
        select: [p.id, p.name, p.blurb]
    players = PokerEx.Repo.all(query)
    render conn, "new.html", changeset: changeset, players: players
  end
  
  def create(conn, %{"invitees" => invitees, "private_room" => %{"title" => title, "owner" => owner} = room_params}) do
    private_room = %PrivateRoom{invitees: [], owner: nil, participants: []}
    changeset = 
      PrivateRoom.changeset(private_room, room_params)
      |> PrivateRoom.put_owner(owner)
      |> PrivateRoom.put_invitees(Map.values(invitees) ++ [owner])
    
    case PokerEx.Repo.insert(changeset) do
      {:ok, room} -> 
        case PokerEx.RoomsSupervisor.create_private_room(title) do
          {:ok, _pid} -> 
            PokerEx.Notifications.notify_invitees(room)
            conn
            |> put_flash(:info, "#{title} has been created")
            |> redirect(to: private_room_path(conn, :show, room.id))
          _ ->
            conn
            |> put_flash(:error, "Could not create room. Please try again.")
            |> redirect(to: private_room_path(conn, :new))
        end
      {:error, _error_changeset} ->
        conn
        |> put_flash(:error, "Something went wrong")
        |> redirect(to: private_room_path(conn, :new))
    end
  end
  
  def show(conn, %{"id" => id}) do
    room = PokerEx.Repo.get(PrivateRoom, String.to_integer(id)) |> PrivateRoom.preload()
    authenticate(conn, room)
    
    render conn, "show.html", room: room
  end
  
  defp authenticate(conn, room) do
    player = conn.assigns[:current_player]
    unless player in room.invitees || player == room.owner || player in room.participants do
      conn
      |> put_flash(:error, "Access restricted")
      |> redirect(to: player_path(conn, :show, conn.assigns[:current_player]))
    end
  end
end