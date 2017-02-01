defmodule PokerEx.TableEvents do
  alias PokerEx.Endpoint
  
  def card_dealt(room_id, card) when is_list(card) do
    card = Enum.map(card, fn c -> Map.from_struct(c) end)
    Endpoint.broadcast("players:" <> room_id, "card_dealt", %{card: card})
  end
  
  def card_dealt(room_id, card) do
    card = Map.from_struct(card)
    Endpoint.broadcast("players:" <> room_id, "card_deal", %{card: card})
  end
  
  def flop_dealt(room_id, flop) do
    cards = Enum.map(flop, fn card -> Map.from_struct(card) end)
    Endpoint.broadcast("players:" <> room_id, "flop_dealt", %{cards: cards})
  end
  
  def pot_update(room_id, amount) do
    Endpoint.broadcast("players:" <> room_id, "pot_update", %{amount: amount})
  end
  
  def update_seating(room_id, seating) do
    seating = Enum.reduce(seating, %{}, fn {name, seat_num}, acc -> Map.put(acc, name, seat_num) end)
    Endpoint.broadcast!("players:" <> room_id, "update_seating", seating)
  end
  
  def call_amount_update(room_id, new_amount) do
    Endpoint.broadcast("players:" <> room_id, "call_amount_update", %{amount: new_amount})
  end
  
  def advance(room_id, {player, _seat}) do
    Endpoint.broadcast("players:" <> room_id, "advance", %{player: player})
  end
  
  def clear_ui(room_id) do
    Endpoint.broadcast("players:" <> room_id, "clear_ui", %{})
  end
  
  def paid_in_round_update(room_id, map) do
    Endpoint.broadcast("players:" <> room_id, "paid_in_round_update", map)
  end
end