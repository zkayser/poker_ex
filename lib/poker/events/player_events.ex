defmodule PokerEx.PlayerEvents do
  alias PokerEx.Endpoint
  
  def chip_update(player, amount) do
    Endpoint.broadcast! "players:lobby", "chip_update", %{player: player.name, chips: amount}
  end
end