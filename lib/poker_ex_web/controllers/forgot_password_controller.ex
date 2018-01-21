defmodule PokerExWeb.ForgotPasswordController do
	use PokerExWeb, :controller
	alias PokerEx.Player

	def forgot_password(conn, %{"email" => email}) do
		case Player.email_exists?(email) do
			false ->
				conn
				|> render(PokerExWeb.PasswordResetView, "error.json", %{})
			true ->
				# case Player.initiate_password_reset(email) do
				# 	%Player{} = player -> PokerEx.Emails.reset_password(player) |> PokerEx.Mailer.deliver_later()
				# 	_ -> render(PokerExWeb.PasswordResetView, "reset_failed.json", %{})
				# end
				conn
				|> render(PokerExWeb.PasswordResetView, "success.json", %{})
		end
	end
end