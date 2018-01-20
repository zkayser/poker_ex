defmodule PokerEx.WelcomeMailerTest do
	use ExUnit.Case, async: true
	use Bamboo.Test
	import PokerEx.TestHelpers
	alias PokerEx.Emails

	@welcome_string "Thank you for joining PokerEx!"

	setup do
		user = insert_user()
		{:ok, user: user}
	end

	test "welcome email", context do
		email = Emails.welcome_email(context.user)

		assert email.to == context.user.email
		assert email.from == "support@pokerex.com"
		assert email.subject =~ "Welcome to PokerEx, #{context.user.name}"
		assert email.html_body =~ @welcome_string
	end
end