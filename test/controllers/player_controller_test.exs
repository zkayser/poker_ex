defmodule PokerEx.PlayerControllerTest do
  use PokerExWeb.ConnCase, async: true
  
  setup do
    player = insert_user(username: "Joe")
    other = insert_user(username: "Other", first_name: "Other")
    conn = assign(build_conn(), :current_player, player)
    %{conn: conn, player: player, other: other}
  end
  
  test "redirects to correct page when accessing :show action on player other than the current player", %{conn: conn} do
    conn = get(conn, player_path(conn, :show, "123"))
    flash_response = get_flash(conn, :error)
    
    assert html_response(conn, 302)
    assert flash_response =~ ~r(Access restricted)
  end
  
  test "no authentication is required for new action", %{conn: conn} do
    conn = get(conn, player_path(conn, :new))
    
    assert html_response(conn, 200)
  end
  
  test "redirects to home page when no user is logged in", %{conn: conn, player: player} do
    conn = assign(conn, :current_player, nil)
    conn = get(conn, player_path(conn, :show, player.id))
    flash_response = get_flash(conn, :error)
    
    assert html_response(conn, 302)
    assert flash_response =~ ~r(You must be logged in)
  end
  
  test "logged in player can access own show action", %{conn: conn, player: player, other: other} do
    conn = get(conn, player_path(conn, :show, Integer.to_string(player.id)))
    
    assert html_response(conn, 200)
    assert String.contains?(conn.resp_body, player.first_name)
    refute String.contains?(conn.resp_body, other.first_name)
  end
end