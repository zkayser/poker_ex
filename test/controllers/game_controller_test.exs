defmodule PokerExWeb.GameControllerTest do
  import Phoenix.LiveViewTest
  use PokerExWeb.ConnCase, async: false

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

    test "renders the Join Game form", %{conn: conn} do
      {:ok, view, _live} = live(conn, "games/game_1")

      assert render(view) =~ "Join Game"
    end
  end
end
