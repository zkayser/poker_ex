defmodule PokerEx.GameEvents do
  alias PokerEx.Endpoint
  alias PokerEx.Player
  alias PokerEx.Repo
  alias PokerEx.PlayerView
  
  def game_started(room_id, room) do
    Endpoint.broadcast!("players:" <> room_id, "game_started", PokerEx.RoomView.render("room.json", %{room: room}))
  end
  
  def state_updated(room_id, update) do
    Endpoint.broadcast!("players:" <> room_id, "state_updated", PokerEx.RoomView.render("room.json", %{room: update}))
  end

  def game_over(room_id, winner, reward) do
    message = "#{winner} wins #{reward} chips"
    Endpoint.broadcast!("players:" <> room_id, "game_finished", %{message: message})
  end
  
  def winner_message(room_id, message) do
    Endpoint.broadcast!("players:" <> room_id, "winner_message", %{message: message})
  end
end