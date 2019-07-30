defmodule PokerExWeb.SessionController do
  use PokerExWeb, :controller

  action_fallback(PokerExWeb.FallbackController)

  def create(conn, %{"player" => %{"username" => username, "password" => pass}}) do
    api_sign_in(conn, username, pass)
  end
end
