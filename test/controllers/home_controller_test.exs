defmodule PokerExWeb.HomeControllerTest do
  alias PokerEx.GameEngine.GameEvents
  alias PokerEx.GameEngine.Impl, as: Game
  import Phoenix.LiveViewTest
  use PokerExWeb.ConnCase

  describe "GET /" do
    test "renders a list of games", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      assert render(view) =~ "data-testid=\"game_card\""
    end

    test "game buttons point to /games/{game_id}", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      assert render(view) =~ "href=\"/games/game_1\""
    end

    test "subscribe to updates from GameEvents", %{conn: conn} do
      initial = PokerEx.GameEngine.get_state("game_1")
      update = %Game{initial | chips: %{pot: 700}}

      {:ok, view, _} = live(conn, "/")

      GameEvents.notify_subscribers(update)

      assert render(view) =~ "700"
    end
  end
end
