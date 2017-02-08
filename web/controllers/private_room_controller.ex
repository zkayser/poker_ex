defmodule PokerEx.PrivateRoomController do
  use PokerEx.Web, :controller
  alias PokerEx.PrivateRoom
  alias PokerEx.Player
  
  def new(conn, params) do
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
  
  def create(conn, %{"invitees" => invitees, "private_room" => %{"title" => title, "owner" => owner} = room_params} = params) do
    private_room = %PrivateRoom{invitees: [], owner: nil, participants: []}
    changeset = 
      PrivateRoom.changeset(private_room, room_params)
      |> PrivateRoom.put_owner(owner)
      |> PrivateRoom.put_invitees(Map.values(invitees))
    
    case PokerEx.Repo.insert(changeset) do
      {:ok, room} -> 
        conn
        |> put_flash(:info, "#{room.title} has been created")
        |> redirect(to: private_room_path(conn, :show, room.id))
      {:error, error_changeset} ->
        conn
        |> put_flash(:error, "Something went wrong")
        |> redirect(to: private_room_path(conn, :new))
    end
  end
  
  def show(conn, %{"id" => id}) do
    room = PokerEx.Repo.get(PrivateRoom, String.to_integer(id)) |> PrivateRoom.preload()
    unless conn.assigns[:current_player] in room.invitees || conn.assigns[:current_player] == room.owner do
      conn
      |> put_flash(:error, "Access restricted")
      |> redirect(to: player_path(conn, :show, conn.assigns[:current_player]))
    end
    
    render conn, "show.html", room: room
  end
end