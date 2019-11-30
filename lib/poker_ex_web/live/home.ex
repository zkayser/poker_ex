defmodule PokerExWeb.Live.Home do
  use Phoenix.LiveView

  def render(assigns) do
    Phoenix.View.render(PokerExWeb.HomeView, "index.html", assigns)
  end

  def mount(%{games: games} = _session, socket) do
    send(self(), :setup)

    {:ok,
     assign(socket,
       games:
         for(game <- games, do: :sys.get_state(PokerEx.GameEngine.GamesSupervisor.name_for(game)))
     )}
  end

  def handle_info(:setup, socket) do
    # PokerEx.GameEngine.subscribe(to: socket.assigns.games)
    {:ok, socket}
  end
end
