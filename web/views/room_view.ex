defmodule PokerEx.RoomView do
  use PokerEx.Web, :view
  alias PokerEx.Room
  
  def render("room.json", %{room: room}) do
    %{active: hd(room.active) || nil,
      current_big_blind: room.current_big_blind || nil,
      current_small_blind: room.current_small_blind || nil,
      paid: room.paid || %{},
      to_call: room.to_call || 0,
      player_hands: Phoenix.View.render_many(room.player_hands, __MODULE__, "player_hands.json", as: :player_hand),
      round: room.round || %{},
      pot: room.pot || 0,
      table: Phoenix.View.render_many(room.table, __MODULE__, "card.json", as: :card)
     }
  end
  
  def render("player_hands.json", %{player_hand: {player, hand}}) do
    %{
      player: player,
      hand: Enum.map(hand, fn card -> Map.from_struct(card) end)
     }
  end
  
  def render("card.json", %{card: card}) do
    %{
      rank: card.rank,
      suit: card.suit
    }
  end
  
  def players_in_room(%PokerEx.Room{seating: seating}) when length(seating) == 1 do
    "1 player currently at table"
  end
  def players_in_room(%PokerEx.Room{seating: seating}) when length(seating) > 1 do
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