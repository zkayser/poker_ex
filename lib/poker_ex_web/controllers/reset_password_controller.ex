defmodule PokerExWeb.ResetPasswordController do
	use PokerExWeb, :controller
	alias PokerEx.Player

	def reset_password(conn, %{"reset_token" => reset_token, "password" => password}) do
		case Player.verify_reset_token(reset_token) do
			:ok ->
				case Player.reset_password(reset_token, %{"password" => password}) do
					{:ok, player} -> api_sign_in(conn, player.name, password)
					{:error, error} -> put_error(conn, error)
				end
			{:error, error} -> put_error(conn, error)
		end
	end

	defp put_error(conn, error) do
		conn
		|> put_status(400)
		|> json(%{message: error, type: "error"})
	end
end