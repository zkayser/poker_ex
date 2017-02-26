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
      {:error, error_changeset} ->
        case hd(error_changeset.errors) do
          {:title, {"has already been taken", []}} ->
            IO.inspect(hd(error_changeset.errors))
            conn
            |> put_flash(:error, "#{title} has already been taken")
            |> redirect(to: private_room_path(conn, :new))
          _ ->
            IO.inspect(hd(error_changeset.errors))
            conn
            |> put_flash(:error, "An unknown error occurred.")
            |> redirect(to: private_room_path(conn, :new))
        end
    end
  end
  
  def show(conn, %{"id" => id}) do
    room = PokerEx.Repo.get(PrivateRoom, String.to_integer(id)) |> PrivateRoom.preload()
    authenticate(conn, room)
    case maybe_restore_state(room.title) do
      :process_alive -> render conn, "show.html", room: room
      :ok -> render conn, "show.html", room: room
      {:error, priv_room} ->
        PrivateRoom.delete(priv_room)
        conn
        |> put_flash(:error, "An error occurred and that room no longer exists.")
        |> redirect(to: player_path(conn, :show, conn.assigns[:current_player]))
    end
  end
  
  defp authenticate(conn, room) do
    player = conn.assigns[:current_player]
    unless player in room.invitees || player == room.owner || player in room.participants do
      conn
      |> put_flash(:error, "Access restricted")
      |> redirect(to: player_path(conn, :show, conn.assigns[:current_player]))
    end
  end
  
  defp maybe_restore_state(id) do
    pid = 
      id
      |> String.to_atom
      |> Process.whereis
    unless pid do
      priv_room = PokerEx.Repo.get_by(PrivateRoom, title: id)
      case {priv_room.room_state, priv_room.room_data} do
        {nil, nil} -> {:error, priv_room}
        {state, data} when is_binary(state) and is_binary(data) ->
          PokerEx.Room.start_link(id |> String.to_atom)
          PokerEx.Room.put_state((id |> String.to_atom), :erlang.binary_to_term(priv_room.room_state), :erlang.binary_to_term(priv_room.room_data))
          :ok
        _ -> {:error, priv_room}
      end
    else
      :process_alive
    end
  end
end