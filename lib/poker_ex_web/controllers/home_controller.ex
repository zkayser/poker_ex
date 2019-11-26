defmodule PokerExWeb.HomeController do
  use PokerExWeb, :controller
  alias Phoenix.LiveView
  alias PokerExWeb.Live.Home

  def index(conn, _params) do
    LiveView.Controller.live_render(conn, Home, session: %{
      games: PokerEx.GameEngine.GamesServer.get_games |> Enum.take(10)
    })
  end
end
