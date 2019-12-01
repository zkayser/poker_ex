defmodule PokerExWeb.Live.Home do
  alias PokerEx.GameEngine.GameEvents
  alias PokerEx.GameEngine
  use Phoenix.LiveView

  def render(assigns) do
    Phoenix.View.render(PokerExWeb.HomeView, "index.html", assigns)
  end

  def mount(%{games: games} = _session, socket) do
    send(self(), {:setup, games})
    {:ok, assign(socket, games: [])}
  end

  def handle_info({:setup, games}, socket) do
    socket =
      socket
      |> assign(games: (for game <- games, do: GameEngine.get_state(game)))

    Enum.each(socket.assigns.games, &GameEvents.subscribe/1)
    {:noreply, socket}
  end

  def handle_info(%Phoenix.Socket.Broadcast{event: "update", payload: %GameEngine.Impl{} = game_update}, socket) do
    socket =
      socket
      |> assign(games: update_game(socket.assigns.games, game_update))

    {:noreply, socket}
  end

  defp update_game(games, update) do
    games
    |> Enum.map(fn game ->
      case game.game_id == update.game_id do
        true -> update
        false -> game
      end
    end)
  end
end
