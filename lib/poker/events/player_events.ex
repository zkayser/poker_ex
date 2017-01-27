defmodule PokerEx.PlayerEvents do
  alias PokerEx.Endpoint
  
  def chip_update(room_id, player, amount) do
    Endpoint.broadcast! "players:" <> room_id, "chip_update", %{player: player.name, chips: amount}
  end
end