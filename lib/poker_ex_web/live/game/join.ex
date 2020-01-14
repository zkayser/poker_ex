defmodule PokerExWeb.Live.Game.Join do
  alias PokerEx.GameEngine
  alias PokerEx.Players.Anon
  require Logger

  def change_name(assign_fn, %{"name" => name}, socket) do
    {:noreply, assign_fn.(socket, name: name)}
  end

  def attempt_join(assign_fn, _params, socket) do
    case socket.assigns.name do
      nil -> {:noreply, socket}
      _name -> join_game(assign_fn, socket)
    end
  end

  defp join_game(assign, %{assigns: %{name: name}} = socket) when is_binary(name) do
    with {:ok, %Anon{} = player} <- Anon.new(%{"name" => name}),
         %GameEngine.Impl{game_id: id} = _engine <- socket.assigns.game,
         :ok <- GameEngine.is_player_seated?(socket.assigns.game.game_id, player),
         %GameEngine.Impl{} <- GameEngine.join(id, player, 1000) do
      {:noreply,
       assign.(socket, current_player: player, errors: Map.delete(socket.assigns.errors, :name))}
    else
      :already_joined ->
        {:noreply,
         assign.(socket,
           errors: Map.put(socket.assigns.errors, :name, "That name has already been taken")
         )}

      error ->
        Logger.warn(
          "Received unhandled error on PokerExWeb.Live.Game.join_game: \n#{
            inspect(error, pretty: true)
          }"
        )

        {:noreply, socket}
    end
  end
end
