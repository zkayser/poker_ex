defmodule PokerExWeb.Live.JoinComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    Phoenix.View.render(PokerExWeb.GameView, "join.html", assigns)
  end

  def handle_event("change_name", %{"name" => name}, socket) do
    {:noreply, assign(socket, :name, name)}
  end
end
