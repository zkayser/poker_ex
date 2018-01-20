defmodule PokerExWeb.ForgotPasswordController do
	use PokerExWeb, :controller
	alias PokerEx.Player

	def forgot_password(conn, %{"email" => email}) do
		case Player.email_exists?(email) do
			false ->
				conn
				|> render(PokerExWeb.PasswordResetView, "error.json", %{})
			true ->
				conn
				|> render(PokerExWeb.PasswordResetView, "success.json", %{})
		end
	end
end