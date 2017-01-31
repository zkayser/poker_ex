defmodule PokerEx.PlayerView do
  use PokerEx.Web, :view
  
  def render("index.json", %{players: players}) do
    %{
      players: Enum.map(players, &player_json/1)
    }
  end
  
  def render("show.json", %{player: player}) do
    player_json(player)
  end
  
  defp player_json(player) do
    %{
      name: player.name,
      chips: player.chips
    }
  end 
end