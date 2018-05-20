defmodule PokerExWeb.PlayerView do
  use PokerExWeb, :view
  alias PokerEx.Player

  # You can just use Phoenix.View.render_many(players, PokerExWeb.PlayerView, "player.json")
  def render("index.json", %{players: players}) do
    %{
      players: Enum.map(players, &player_json/1)
    }
  end

  # TODO: Deprecate and remove
  def render("show.json", %{player: player}) do
    player_json(player)
  end

  def render("player.json", %{player: player}) do
    %{
      id: player.id,
      name: player.name,
      chips: player.chips,
      blurb: player.blurb,
      firstName: player.first_name,
      lastName: player.last_name,
      email: player.email
    }
  end

  def render("player_list.json", %{players: players}) do
    for [id, name, blurb] <- players do
      %{
        name: name,
        id: id,
        blurb: blurb
      }
    end
  end

  # TODO: Deprecate and remove
  defp player_json(player) do
    %{
      name: player.name,
      chips: player.chips,
      firstName: player.first_name,
      lastName: player.last_name,
      email: player.email
    }
  end

  def full_name(%Player{first_name: first, last_name: last}) do
    "#{String.capitalize(first)} #{String.capitalize(last)}'s Profile"
  end

  def full_name(%Player{name: name}), do: "#{String.capitalize(name)}'s Profile"

  defp paginated_entries(list) when is_list(list) do
    Scrivener.paginate(list, page_number: 1, page_size: 10).entries
  end

  def limit_pages(list) when is_list(list) do
    case Scrivener.paginate(list, page_number: 1, page_size: 10).total_pages do
      x when x < 5 -> x
      _ -> 5
    end
  end
end
