defmodule PokerExWeb.PasswordResetViewTest do
	use PokerExWeb.ConnCase, async: true
	import Phoenix.View

	test "renders success.json" do
		json = render(PokerExWeb.PasswordResetView, "success.json", %{})

		expected = %{
			"message" => "An email has been sent with a link to reset your password",
			"type" => "success"
		}

		assert json == expected
	end

	test "renders error.json" do
		json = render(PokerExWeb.PasswordResetView, "error.json", %{})

		expected = %{
			"message" => "No user exists with the email provided",
			"type" => "error"
		}

		assert json == expected
	end
end