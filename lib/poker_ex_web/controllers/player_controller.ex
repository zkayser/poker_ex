defmodule PokerExWeb.PlayerController do
  use PokerExWeb, :controller
  alias PokerEx.Player

  def list(conn, %{"player" => player, "page" => page}) do
    query =
      from(p in Player,
        where: p.name != ^player,
        order_by: [asc: :id],
        select: [p.id, p.name, p.blurb]
      )

    page = Repo.all(query) |> Repo.paginate(%{page: page})

    render(conn, "player_list.json",
      players: page.entries,
      current_page: page.page_number,
      total: page.total_pages
    )
  end
end
