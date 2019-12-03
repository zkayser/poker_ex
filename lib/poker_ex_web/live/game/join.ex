defmodule PokerExWeb.Live.JoinComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    Phoenix.View.render(PokerExWeb.GameView, "join.html", assigns)
  end
end
