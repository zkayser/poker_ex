defmodule PokerExWeb.ResetPasswordControllerTest do
  use PokerExWeb.ConnCase, async: false
  import PokerEx.TestHelpers
  alias PokerEx.Player

  setup do
    player = insert_user()
    {:ok, player} = Player.initiate_password_reset(player.email)

    conn = build_conn()

    {:ok, player: player, conn: conn}
  end

  test "renders login.json with a status of 200 when the token is verified and pw change is successful",
       context do
    params = %{"reset_token" => context.player.reset_token, "password" => "secretpassword"}

    response =
      context.conn
      |> post(reset_password_path(context.conn, :reset_password, params))
      |> json_response(200)

    assert response["player"]["email"] == context.player.email
    assert response["player"]["username"] == context.player.name
    assert response["player"]["chips"] == context.player.chips
  end

  test "returns a 400 status code if the token is invalid", context do
    params = %{"reset_token" => "a bunch of invalid garbage", "password" => "secretpassword"}

    response =
      context.conn
      |> post(reset_password_path(context.conn, :reset_password, params))
      |> json_response(400)

    assert response["type"] == "error"
    assert response["message"] == "The token is invalid"
  end
end
