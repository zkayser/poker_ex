defmodule PokerEx.RoomEvents do
  alias PokerExWeb.Endpoint
  
  
  # Position denotes the player's seating position at the table
  def player_joined(room_id, player, position) do
    Endpoint.broadcast!("players:" <> room_id, "player_seated", %{player: player, position: position})
  end
  
  def player_left(room_id, player) do
    Endpoint.broadcast!("players:" <> room_id, "player_got_up", %{player: player})
  end
end