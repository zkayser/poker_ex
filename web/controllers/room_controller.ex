defmodule PokerEx.RoomController do
  use PokerEx.Web, :controller
  alias PokerEx.RoomsSupervisor, as: RoomsSupervisor
  
  def index(conn, _params) do
    [{pid, _}] = Registry.lookup(PokerEx.RoomRegistry, "room_1")
    ids = Registry.keys(PokerEx.RoomRegistry, pid)
    
    {_, room_states} = Enum.map_reduce(ids, %{}, 
      fn (room, acc) ->
        {{room, :state}, Map.put(acc, String.to_atom(room), PokerEx.Room.state(String.to_atom(room)))}
      end)
    
    render conn, "index.html", rooms: Map.values(room_states)
  end
  
  def create(conn, %{"name" => name} = _params) when is_binary(name) do
    case RoomsSupervisor.room_process_exists?(String.to_atom(name)) do
      true -> 
        conn
        |> put_flash(:error, "A room with the name #{name} already exists")
        |> redirect(to: player_path(conn, :show, conn.current_player.id))
      _ ->
        conn
        |> put_flash(:info, "Room #{name} created!")
        |> redirect(to: room_path(conn, :show, name))
    end
  end
  
  def show(conn, %{"id" => name}) do
    room = PokerEx.Room.state(name |> String.to_atom)
    render conn, "show.html", [room: room, current_player: conn.assigns[:current_player], conn: conn]
  end
end