defmodule PokerEx.Events do
  alias PokerEx.GameEvents
  alias PokerEx.PlayerEvents
  alias PokerEx.RoomEvents
  alias PokerEx.TableEvents
  
  def player_joined(player, position) do
    RoomEvents.player_joined(player, position)
  end

  def game_started(active, cards) do
    GameEvents.game_started(active, cards)
  end
  
  def advance(player) do
    TableEvents.advance(player)
  end
  
  def card_dealt(card) do
    TableEvents.card_dealt(card)
  end
  
  def flop_dealt(flop) do
    TableEvents.flop_dealt(flop)
  end
  
  def pot_update(amount) do
    TableEvents.pot_update(amount)
  end
  
  def call_amount_update(new_amount) do
    TableEvents.call_amount_update(new_amount)
  end
  
  def game_over(winner, reward) do
    GameEvents.game_over(winner, reward)
  end
  
  def winner_message(message) do
    GameEvents.winner_message(message)
  end
  
  def player_left(player) do
    RoomEvents.player_left(player)
  end
  
  def chip_update(player, amount) do
    PlayerEvents.chip_update(player, amount)
  end
end