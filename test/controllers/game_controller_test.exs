defmodule PokerExWeb.GameControllerTest do
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
  end
end
