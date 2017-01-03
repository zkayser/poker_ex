defmodule PokerEx.RoomEvents do
  use GenEvent
  alias PokerEx.Endpoint
  
  def init([]) do
    {:ok, []}
  end
  
  # Position denotes the player's seating position at the table
  def handle_event({:player_joined, player, position}, state) do
    Endpoint.broadcast!("players:lobby", "player_seated", %{player: player, position: position})
    {:ok, state}
  end
  
  def handle_event({:player_left, player}, state) do
    Endpoint.broadcast!("players:lobby", "player_got_up", %{player: player})
    {:ok, state}
  end
  
  def handle_event(_event, state), do: {:ok, state}
end