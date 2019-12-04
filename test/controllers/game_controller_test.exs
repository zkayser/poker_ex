defmodule PokerExWeb.GameControllerTest do
  alias PokerExWeb.Live.JoinComponent
  import Phoenix.LiveViewTest
  use PokerExWeb.ConnCase

  setup do
    conn = build_conn()

    {:ok, conn: conn}
  end

  describe "GET /games" do
    test "handles incoming requests", %{conn: conn} do
      assert conn
             |> get("/games/game_1")
             |> html_response(200)
    end

    test "renders the JoinComponent", %{conn: conn} do
      {:ok, view, _live} = live(conn, "games/game_1")

      assert render(view) =~ "Join Game"
    end
  end
end
