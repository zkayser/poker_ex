defmodule PokerEx.PlayerView do
  use PokerEx.Web, :view
  alias PokerEx.Player
  
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
  
  def full_name(%Player{first_name: first, last_name: last}) do
    "#{String.capitalize(first)} #{String.capitalize(last)}'s Profile"
  end
  def full_name(%Player{name: name}), do: "#{String.capitalize(name)}'s Profile"
end