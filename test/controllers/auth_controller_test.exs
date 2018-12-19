defmodule PokerExWeb.AuthControllerTest do
  use PokerExWeb.ConnCase, async: true

  @unauthorized_message "Authorization failed"

  setup do
    facebook_id = Base.encode16(:crypto.strong_rand_bytes(8))
    {:ok, player} = Repo.insert(%PokerEx.Player{name: "some user", facebook_id: facebook_id})
    conn = build_conn()
    %{conn: conn, player: player}
  end

  test "returns a status of 200 on oauth_handler for valid provider and existing user", context do
    received_json = %{"name" => context.player.name, "facebook_id" => context.player.facebook_id}
    conn = post(context.conn, auth_path(context.conn, :oauth_handler, received_json))
    assert json_response(conn, 200)
    assert String.contains?(conn.resp_body, "player")
  end

  test "returns a status of 200 on oauth_handler for valid provider and non-existing user",
       context do
    received_json = %{
      "name" => "some name",
      "facebook_id" => "#{Base.encode16(:crypto.strong_rand_bytes(8))}"
    }

    conn = post(context.conn, auth_path(context.conn, :oauth_handler, received_json))
    assert json_response(conn, 200)
    assert String.contains?(conn.resp_body, "player")
  end

  test "returns unauthorized when facebook_id and player name do not match", context do
    received_json = %{
      "name" => "some different name",
      "facebook_id" => context.player.facebook_id
    }

    conn = post(context.conn, auth_path(context.conn, :oauth_handler, received_json))
    assert json_response(conn, 401)
    assert String.contains?(conn.resp_body, @unauthorized_message)
  end
end
