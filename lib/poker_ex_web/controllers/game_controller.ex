defmodule PokerExWeb.GameController do
  use PokerExWeb, :controller
  alias PokerExWeb.Live.Game
  alias Phoenix.LiveView

  def show(conn, %{"id" => game_id}) do
    LiveView.Controller.live_render(conn, Game,
      session: %{
        game: game_id
      }
    )
  end
end
