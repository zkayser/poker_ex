defmodule PokerExWeb.GameController do
  use PokerExWeb, :controller

  def show(conn, %{"id" => _game_id}) do
    render(conn, "show.html")
  end
end
