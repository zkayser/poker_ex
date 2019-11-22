defmodule PokerExWeb.HomeController do
  use PokerExWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
