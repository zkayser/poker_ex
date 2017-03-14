defmodule PokerEx.PlayerControllerTest do
  use PokerEx.ConnCase
  
  test "requires authentication on show action", %{conn: conn} do
    conn = get(conn, player_path(conn, :show, "123"))
    
    assert html_response(conn, 302)
    assert conn.halted
  end
  
  test "no authentication is required for new action", %{conn: conn} do
    conn = get(conn, player_path(conn, :new))
    
    assert html_response(conn, 200)
  end
end