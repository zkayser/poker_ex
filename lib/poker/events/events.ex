defmodule PokerEx.Events do
  alias PokerEx.{GameEvents, RoomEvents, TableEvents, LobbyEvents}

  def player_joined(game_id, player, position) do
    RoomEvents.player_joined(game_id, player, position)
  end

  def state_updated(game_id, update) do
    GameEvents.state_updated(game_id, update)
  end

  def update_number_players(game_id, number) do
    LobbyEvents.update_number_players(game_id, number)
  end

  def game_started(game_id, room) do
    GameEvents.game_started(game_id, room)
  end

  def advance(game_id, player) do
    TableEvents.advance(game_id, player)
  end

  def card_dealt(game_id, card) do
    TableEvents.card_dealt(game_id, card)
  end

  def flop_dealt(game_id, flop) do
    TableEvents.flop_dealt(game_id, flop)
  end

  def update_seating(game_id, seating) do
    TableEvents.update_seating(game_id, seating)
  end

  def clear_ui(game_id) do
    TableEvents.clear_ui(game_id)
  end

  def clear(game_id, update) do
    GameEvents.clear(game_id, update)
  end

  def game_over(game_id, winner, reward) do
    GameEvents.game_over(game_id, winner, reward)
  end

  def winner_message(game_id, message) do
    GameEvents.winner_message(game_id, message)
  end

  def present_winning_hand(game_id, winning_hand, player, type) do
    GameEvents.present_winning_hand(game_id, winning_hand, player, type)
  end

  def update_player_count(game) do
    LobbyEvents.update_player_count(game)
  end
end
