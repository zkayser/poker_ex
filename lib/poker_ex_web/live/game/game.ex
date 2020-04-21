defmodule PokerExWeb.Live.Game do
  alias PokerEx.GameEngine
  alias PokerExWeb.Live.Game.Join
  require Logger
  use Phoenix.LiveView

  @join_events ~w(change_name attempt_join)
  @poker_actions ~w(call raise fold check)

  def render(assigns) do
    Phoenix.View.render(PokerExWeb.GameView, "show.html", assigns)
  end

  def mount(%{game: game_id}, socket) do
    send(self(), {:setup, game_id})

    {:ok,
     assign(socket,
       game: nil,
       current_player: nil,
       name: nil,
       errors: %{},
       show_raise_form: false,
       raise_amount: 0
     )}
  end

  def handle_info({:setup, game_id}, socket) do
    game = GameEngine.get_state(game_id)
    GameEngine.GameEvents.subscribe(game)
    {:noreply, assign(socket, :game, game)}
  end

  def handle_info(%{event: "update", payload: %GameEngine.Impl{} = game}, socket) do
    {:noreply, assign(socket, :game, game)}
  end

  def handle_event(event, %{"name" => _name} = params, socket) when event in @join_events do
    apply(Join, String.to_existing_atom(event), [assign_function(), params, socket])
  end

  def handle_event(event, params, socket) when event in @join_events do
    apply(Join, String.to_existing_atom(event), [assign_function(), params, socket])
  end

  def handle_event("action_" <> move, _params, socket) when move in @poker_actions do
    apply(GameEngine, String.to_existing_atom(move), [
      socket.assigns.game.game_id,
      socket.assigns.current_player
    ])

    {:noreply, socket}
  end

  def handle_event("show_raise_form", _params, socket) do
    {:noreply, assign(socket, show_raise_form: true)}
  end

  def handle_event("close_raise_form", _params, socket) do
    {:noreply, assign(socket, show_raise_form: false)}
  end

  def handle_event("change_raise_amount", %{"raise_amount" => amount}, socket) do
    case Integer.parse(amount) do
      {amount, _} -> {:noreply, assign(socket, raise_amount: amount)}
      :error -> {:noreply, socket}
    end
  end

  def handle_event("submit_raise", _, socket) do
    GameEngine.raise(
      socket.assigns.game.game_id,
      socket.assigns.current_player,
      socket.assigns.raise_amount
    )

    {:noreply, assign(socket, show_raise_form: false, raise_amount: 0)}
  end

  defp assign_function do
    fn socket, keyword ->
      assign(socket, keyword)
    end
  end
end
