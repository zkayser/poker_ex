defmodule PokerExWeb.GameControllerTest do
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

  describe "join" do
    @component "join"
    test "entering a name in the name-input field populates the player's name", %{conn: conn} do
      {:ok, view, _html} = live(conn, "games/game_1")
      name = "some player name"

      assert render_change([view, @component], :change_name, %{"name" => name}) =~ name
    end

    test "entering a name in the name-input field enables the join game button", %{conn: conn} do
      {:ok, view, _html} = live(conn, "games/game_1")
      name = "some player name"

      html = render_change([view, @component], :change_name, %{"name" => name})
      refute html =~ "disabled"
    end
  end
end
