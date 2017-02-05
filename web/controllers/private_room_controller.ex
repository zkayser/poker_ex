defmodule PokerEx.PrivateRoomController do
  use PokerEx.Web, :controller
  alias PokerEx.PrivateRoom
  
  def new(conn, params) do
    changeset = PrivateRoom.changeset(%PrivateRoom{invitees: []}, %{})
    query = 
      from p in PokerEx.Player,
        where: p.id != ^conn.assigns[:current_player].id,
        limit: 25,
        order_by: [asc: :id],
        select: [p.id, p.name, p.blurb]
    players = PokerEx.Repo.all(query)
    render conn, "new.html", changeset: changeset, players: players
  end
  
  def create(conn, params) do
    IO.puts "Priv Room create params: \nParams: #{inspect(params)}"
    conn
    |> redirect(to: private_room_path(conn, :new))
  end
end