defmodule PokerExWeb.PasswordResetView do
  use PokerExWeb, :view

  @message "An email has been sent with a link to reset your password"
  @error "No user exists with the email provided"
  @failed "Password reset failed. Please re-submit the form and try again"

  def render("success.json", %{}) do
    %{"data" => %{"message" => @message, "type" => "success"}}
  end

  def render("error.json", %{}) do
    %{"data" => %{"message" => @error, "type" => "error"}}
  end

  def render("reset_failed.json", %{}) do
    %{"data" => %{"message" => @failed, "type" => "error"}}
  end
end
