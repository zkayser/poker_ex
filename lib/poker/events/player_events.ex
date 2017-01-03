defmodule PokerEx.PlayerEvents do
  use GenEvent
  alias PokerEx.Endpoint
  
  def init([]) do
    {:ok, []}
  end
  
  def handle_event({:chip_update, player, amount}, state) do
    Endpoint.broadcast! "players:lobby", "chip_update", %{player: player.name, chips: amount}
    {:ok, state}
  end
  
  def handle_event(_event, state), do: {:ok, state}
end