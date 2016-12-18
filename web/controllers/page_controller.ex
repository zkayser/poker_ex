defmodule PokerEx.PageController do
  use PokerEx.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
