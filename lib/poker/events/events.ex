defmodule PokerEx.Events do
  alias PokerEx.GameEvents
  alias PokerEx.PlayerEvents
  alias PokerEx.RoomEvents
  alias PokerEx.TableEvents
  alias PokerEx.LobbyEvents
  
  def player_joined(room_id, player, position) do
    RoomEvents.player_joined(stringify(room_id), player, position)
  end
  
  def state_updated(room_id, update) do
    GameEvents.state_updated(stringify(room_id), update)
  end
  
  def update_number_players(room_id, number) do
    LobbyEvents.update_number_players(stringify(room_id), number)
  end

  def game_started(room_id, room) do
    GameEvents.game_started(stringify(room_id), room)
  end
  
  def advance(room_id, player) do
    IO.puts "advance event called"
    TableEvents.advance(stringify(room_id), player)
  end
  
  def card_dealt(room_id, card) do
    TableEvents.card_dealt(stringify(room_id), card)
  end
  
  def flop_dealt(room_id, flop) do
    TableEvents.flop_dealt(stringify(room_id), flop)
  end
  
  def pot_update(room_id, amount) do
    IO.puts "event called"
    #TableEvents.pot_update(stringify(room_id), amount)
  end
  
  def update_seating(room_id, seating) do
    TableEvents.update_seating(stringify(room_id), seating)
  end
  
  def call_amount_update(room_id, new_amount) do
    IO.puts "Event called"
    #TableEvents.call_amount_update(stringify(room_id), new_amount)
  end
  
  def clear_ui(room_id) do
    TableEvents.clear_ui(stringify(room_id))
  end
  
  def game_over(room_id, winner, reward) do
    GameEvents.game_over(stringify(room_id), winner, reward)
  end
  
  def winner_message(room_id, message) do
    GameEvents.winner_message(stringify(room_id), message)
  end
  
  def player_left(room_id, player) do
    RoomEvents.player_left(stringify(room_id), player)
  end
  
  def chip_update(room_id, player, amount) do
    IO.puts "event called"
    #PlayerEvents.chip_update(stringify(room_id), player, amount)
  end
  
  def paid_in_round_update(room_id, map) do
    IO.puts "event called"
    #TableEvents.paid_in_round_update(stringify(room_id), map)
  end
  
  defp stringify(id) when is_atom(id), do: Atom.to_string(id)
  defp stringify(id), do: id 
end