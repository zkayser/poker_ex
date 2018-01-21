defmodule PokerExWeb.ResetPasswordEmailTest do
	use ExUnit.Case, async: true
	import PokerEx.TestHelpers

	alias PokerEx.Player
	alias PokerEx.Repo
	alias PokerEx.Emails

	setup do
		email = "email#{random_string()}@email.com"
		player = %Player{
			name: "user#{random_string()}",
			email: email,
			reset_token: Phoenix.Token.sign(PokerExWeb.Endpoint, "user salt", email)
		}

		{:ok, player} = Repo.insert(player)

		{:ok, player: player}
	end

	test "Email contains a link with the reset_token", context do
		email = Emails.password_reset(context.player)

		endpoint = "#{Application.get_env(:poker_ex, :client_password_reset_endpoint)}/#{context.player.reset_token}"

		assert email.to == context.player.email
		assert email.from == "support@pokerex.com"
		assert email.subject == "Password Reset Link"
		assert email.html_body =~ "#{context.player.reset_token}"
		assert email.html_body =~ endpoint
		assert email.html_body =~ "Your link will expire in 24 hours"
	end
end