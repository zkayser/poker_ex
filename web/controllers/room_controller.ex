defmodule PokerEx.RoomController do
  use PokerEx.Web, :controller
  
  def show(conn, params) do
    render conn, "show.html"
  end

end