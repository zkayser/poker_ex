defmodule PokerExWeb.PageView do
  use PokerExWeb, :view

  def players_in_game(%PokerEx.GameEngine.Impl{seating: %{arrangement: arrangement}})
      when length(arrangement) > 0 do
    "#{length(arrangement)} players currently at table"
  end

  def players_in_game(_), do: "There are no players currently at the table"

  def game_id(%PokerEx.GameEngine.Impl{game_id: game_id}) when not is_nil(game_id) do
    game_id
    |> String.split("_")
    |> Enum.join(" ")
    |> String.capitalize()
  end

  def game_id(_), do: "No id"

  def sort_games(games) do
    Enum.sort(games, fn g1, g2 ->
      {str1, str2} = {g1.game_id, g2.game_id}
      {[_, num1], [_, num2]} = {String.split(str1, "_"), String.split(str2, "_")}
      Integer.parse(num1) < Integer.parse(num2)
    end)
  end
end
