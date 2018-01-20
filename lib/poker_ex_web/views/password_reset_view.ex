defmodule PokerExWeb.PasswordResetView do
	use PokerExWeb, :view

	@message "An email has been sent with a link to reset your password"
	@error "No user exists with the email provided"

	def render("success.json", %{}) do
		%{"message" => @message, "type" => "success"}
	end

	def render("error.json", %{}) do
		%{"message" => @error, "type" => "error"}
	end
end