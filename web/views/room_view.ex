defmodule PokerEx.RoomView do
  use PokerEx.Web, :view
  
  def players_in_room(%PokerEx.Room{seating: seating}) when length(seating) > 0 do
    "#{length(seating)} players currently at table"
  end
  def players_in_room(_), do: "There are no players currently at the table"
  
  def room_id(%PokerEx.Room{room_id: room_id}) when not is_nil(room_id) do
    room_id
    |> Atom.to_string
    |> String.split("_")
    |> Enum.join(" ")
    |> String.capitalize
  end
  def room_id(_), do: "No id"
  
  def sort_rooms(rooms) do
    Enum.sort(rooms, 
      fn r1, r2 ->
        {str1, str2} = {Atom.to_string(r1.room_id), Atom.to_string(r2.room_id)}
        {[_, num1], [_, num2]} = {String.split(str1, "_"), String.split(str2, "_")}
        Integer.parse(num1) < Integer.parse(num2)
      end)
  end
end