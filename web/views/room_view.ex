defmodule PokerEx.RoomView do
  use PokerEx.Web, :view
  alias PokerEx.Room
  import Ecto.Query
  
  def render("room.json", %{room: room}) do
    {active, _} = if room.active == [], do: {nil, nil}, else: hd(room.active)
    players = 
      if room.active == [] do
        []
      else
        Enum.map(room.active, 
          fn {name, _} -> 
            PokerEx.Repo.one(from p in PokerEx.Player, where: p.name == ^name)
          end)
      end
      
    %{active: active,
      current_big_blind: room.current_big_blind || nil,
      current_small_blind: room.current_small_blind || nil,
      state: Room.which_state(room.room_id),
      paid: room.paid || %{},
      to_call: room.to_call || 0,
      players: Phoenix.View.render_many(players, PokerEx.PlayerView, "player.json"),
      chip_roll: room.chip_roll,
      type: Atom.to_string(room.type),
      seating: Phoenix.View.render_many(room.seating, __MODULE__, "seating.json", as: :seating),
      player_hands: Phoenix.View.render_many(room.player_hands, __MODULE__, "player_hands.json", as: :player_hand),
      round: room.round || %{},
      pot: room.pot || 0,
      table: (if room.table == [], do: [], else:  Phoenix.View.render_many(room.table, __MODULE__, "card.json", as: :card))
     }
  end
  
  def render("full_room.json", %{room: room}) do
    {active, _} = hd(room.active)
    players = Enum.map(room.active, fn {p, _} -> PokerEx.Repo.get_by(PokerEx.Player, name: p) end)
    
    %{active: active,
      state: Room.which_state(room.room_id),
      paid: room.paid,
      to_call: room.to_call,
      players: Phoenix.View.render_many(players, PokerEx.PlayerView, "player.json"),
      type: Atom.to_string(room.type),
      player_hands: Phoenix.View.render_many(room.player_hands, __MODULE__, "player_hands.json", as: :player_hand),
      round: room.round,
      pot: room.pot,
      table: []
    }
  end
  
  def render("player_hands.json", %{player_hand: {_, []}}), do: %{}
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
  
  def render("seating.json", %{seating: {name, position}}) do
    %{
      name: name,
      position: position
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