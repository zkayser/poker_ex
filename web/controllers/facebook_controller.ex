defmodule PokerEx.FacebookController do
  use PokerEx.Web, :controller
  
  def fb_redirect(conn, _params) do
    conn
    |> redirect(to: "/")
  end
end