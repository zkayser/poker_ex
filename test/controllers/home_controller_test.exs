defmodule PokerExWeb.HomeControllerTest do
  use PokerExWeb.ConnCase

  setup do
    conn = build_conn()

    {:ok, conn: conn}
  end

  describe "GET /" do
    test "renders game cards", %{conn: conn} do
      assert conn
        |> get("/")
        |> html_response(200) =~ "data-testid=\"game_card\""
    end
  end
end
