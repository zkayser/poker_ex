defmodule PokerExWeb.RegistrationControllerTest do
  use PokerExWeb.ConnCase, async: false
  use Bamboo.Test

  defp registration_params do
    %{
      "registration" => %{
        "first_name" => "User",
        "last_name" => "Person",
        "name" => "user#{Base.encode16(:crypto.strong_rand_bytes(8))}",
        "email" => "email#{Base.encode16(:crypto.strong_rand_bytes(8))}",
        "blurb" => " ",
        "password" => "secretpassword"
      }
    }
  end

  setup do
    conn = build_conn()
    [conn: conn]
  end

  test "renders SessionView's login.json with a 200 response with valid params", context do
    conn = post(context.conn, registration_path(context.conn, :create, registration_params()))

    assert json_response(conn, 200)
    assert conn.resp_body =~ ~r(\"token\":)
  end

  test "welcome email is sent upon registration", context do
    params = registration_params()
    player_params = params["registration"]
    post(context.conn, registration_path(context.conn, :create, params))

    player = %PokerEx.Player{name: player_params["name"], email: player_params["email"]}
    assert_delivered_email(PokerEx.Emails.welcome_email(player))
  end
end
