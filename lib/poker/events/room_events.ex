defmodule PokerEx.RoomEvents do
  use GenEvent
  alias PokerEx.Endpoint
  
  
  # Position denotes the player's seating position at the table
  def player_joined(player, position) do
    Endpoint.broadcast!("players:lobby", "player_seated", %{player: player, position: position})
  end
  
  def player_left(player) do
    Endpoint.broadcast!("players:lobby", "player_got_up", %{player: player})
  end
end