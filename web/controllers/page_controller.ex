defmodule PokerEx.PageController do
  use PokerEx.Web, :controller

  def index(conn, _params) do
    [{pid, _}] = Registry.lookup(PokerEx.RoomRegistry, "room_1")
    ids = Registry.keys(PokerEx.RoomRegistry, pid)
    
    {_, room_states} = Enum.map_reduce(ids, %{}, 
      fn (room, acc) ->
        {{room, :state}, Map.put(acc, String.to_atom(room), PokerEx.Room.state(String.to_atom(room)))}
      end)
      
    render conn, "index.html", rooms: Map.values(room_states)
  end
end
