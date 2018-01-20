defmodule PokerExWeb.ForgotPasswordControllerTest do
	use PokerExWeb.ConnCase, async: true
	import PokerEx.TestHelpers

	setup do
		player = insert_user()

		{:ok, player: player, conn: build_conn()}
	end

	test "returns a 200 status and an success message when email exists", %{conn: conn, player: player} do
		response = conn
			|> post(forgot_password_path(conn, :forgot_password, %{"email" => player.email}))
			|> json_response(200)

		expected_response = %{
			"message" => "An email has been sent with a link to reset your password",
			"type" => "success"
		}

		assert response == expected_response
	end

	test "returns a 200 status and an error message when email doesn't exist", %{conn: conn} do
		response = conn
			|> post(forgot_password_path(conn, :forgot_password, %{"email" => "nonexistent@nonexistent.com"}))
			|> json_response(200)

		expected_response = %{
			"message" => "No user exists with the email provided",
			"type" => "error"
		}

		assert response == expected_response
	end
end