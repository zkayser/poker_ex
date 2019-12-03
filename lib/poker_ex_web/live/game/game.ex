defmodule PokerExWeb.Live.Game do
  use Phoenix.LiveView

  def render(assigns) do
    Phoenix.View.render(PokerExWeb.GameView, "show.html", assigns)
  end

  def mount(_session, socket) do
    {:ok, socket}
  end
end
