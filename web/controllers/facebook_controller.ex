defmodule PokerEx.FacebookController do
  use PokerExWeb, :controller

  def fb_redirect(conn, _params) do
    conn
    |> redirect(to: "/protected/rooms")
  end
end
