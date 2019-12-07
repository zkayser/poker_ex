defmodule PokerExWeb.Live.Game do
  alias PokerEx.GameEngine
  alias PokerEx.Players.Anon
  use Phoenix.LiveView

  def render(assigns) do
    Phoenix.View.render(PokerExWeb.GameView, "show.html", assigns)
  end

  def mount(%{game: game_id}, socket) do
    send(self(), {:setup, game_id})
    {:ok, assign(socket, game: nil, current_player: nil, name: nil)}
  end

  def handle_info({:setup, game_id}, socket) do
    game = GameEngine.get_state(game_id)
    GameEngine.GameEvents.subscribe(game)
    {:noreply, assign(socket, :game, game)}
  end

  def handle_info(%{event: "update", payload: %GameEngine.Impl{} = game}, socket) do
    {:noreply, assign(socket, :game, game)}
  end

  def handle_event("change_name", %{"name" => name}, socket) do
    {:noreply, assign(socket, :name, name)}
  end

  def handle_event("attempt_join", _value, socket) do
    case socket.assigns.name do
      nil -> {:noreply, socket}
      _name -> join_game(socket)
    end
  end

  defp join_game(%{assigns: %{name: name}} = socket) when is_binary(name) do
    with {:ok, %Anon{} = player} <- Anon.new(%{"name" => name}),
      %GameEngine.Impl{game_id: id} = _engine <- socket.assigns.game,
      %GameEngine.Impl{} <- GameEngine.join(id, player, 1000) do
        {:noreply, assign(socket, current_player: player)}
    else
    error ->
      IO.inspect error, label: "Error from joining"
      {:noreply, socket}
    end
  end
end
