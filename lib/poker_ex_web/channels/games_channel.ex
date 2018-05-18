defmodule PokerExWeb.GamesChannel do
  use Phoenix.Channel
  require Logger
  alias PokerEx.{Repo, Player, PrivateRoom}
  alias PokerEx.GameEngine, as: Game
  alias PokerEx.GameEngine.Seating

  @valid_params ~w(player amount)
  @actions ~w(raise call check fold leave add_chips join)
  @poker_actions ~w(raise call check fold)
  @manual_join_msg "Welcome. Please join by pressing the join button and entering an amount."

  ########
  # JOIN #
  ########

  def join("games:" <> game_title, %{"type" => type, "amount" => amount}, socket)
      when amount >= 100 do
    unless Map.has_key?(socket.assigns, :player) do
      socket =
        assign(socket, :game, game_title)
        |> assign(:type, type)
        |> assign(:join_amount, amount)
        |> assign_player()

      send(self(), :after_join)
      Logger.debug("Player: #{socket.assigns.player.name} has joined game #{game_title}")
      {:ok, %{name: socket.assigns.player.name}, socket}
    end
  end

  # This is a private game join for players who are already seated. All public joins
  # should go through the function above, as well as the initial join to a private game.
  def join("games:" <> game_title, %{"type" => "private", "amount" => 0}, socket) do
    socket =
      assign(socket, :game, game_title)
      |> assign(:type, "private")
      |> assign(:join_amount, 0)
      |> assign_player()

    case Seating.is_player_seated?(Game.get_state(game_title), socket.assigns.player.name) do
      true ->
        send(self(), :after_join)
        Logger.debug("Player #{socket.assigns.player.name} is joining private game #{game_title}")
        {:ok, %{name: socket.assigns.player.name}, socket}

      false ->
        {:error, %{message: @manual_join_msg}}
    end
  end

  def join("games:" <> _, _, _socket) do
    {:error, %{message: "Failed to join the game. Please try again."}}
  end

  #############
  # CALLBACKS #
  #############

  ############
  # INTERNAL #
  ############

  def handle_info(:after_join, %{assigns: assigns} = socket) do
    seating = Enum.map(Game.get_state(assigns.game).seating.arrangement, fn {name, _} -> name end)

    case {assigns.type == "private", assigns.player.name in seating} do
      {true, true} ->
        game = Game.get_state(assigns.game)
        broadcast!(socket, "update", PokerExWeb.GameView.render("game.json", %{game: game}))

      {_, _} ->
        game = Game.join(assigns.game, assigns.player, assigns.join_amount)
        broadcast!(socket, "update", PokerExWeb.GameView.render("game.json", %{game: game}))
    end

    {:noreply, socket}
  end

  ############
  # INCOMING #
  ############

  def handle_in("action_" <> action, %{"player" => _player} = params, socket)
      when action in @actions do
    {player, params} = get_player_and_strip_params(params)

    case Enum.all?(Map.keys(params), &(&1 in @valid_params)) do
      true ->
        game = apply(Game, atomize(action), [socket.assigns.game, player | Map.values(params)])
        save_private_game(game, socket)
        broadcast_action_message(player, action, params, socket)
        maybe_broadcast_update(game, socket)

      _ ->
        {:error, :bad_room_arguments, Map.values(params)}
    end

    {:noreply, socket}
  end

  def handle_in("get_bank", %{"player" => player}, socket) do
    case Player.chips(player) do
      {:error, _} -> :error
      res -> push(socket, "bank_info", %{chips: res})
    end

    {:noreply, socket}
  end

  def handle_in("chat_msg", %{"player" => player, "message" => message}, socket) do
    broadcast!(socket, "new_chat_msg", %{player: player, message: message})
    {:noreply, socket}
  end

  #############
  # TERMINATE #
  #############

  def terminate(reason, socket) do
    Logger.debug("[GamesChannel] Terminating with reason: #{inspect(reason)}")

    game =
      case Game.get_state(socket.assigns.game).type do
        :private -> socket.assigns.game
        :public -> Game.leave(socket.assigns.game, socket.assigns.player)
      end

    broadcast!(socket, "update", PokerExWeb.GameView.render("game.json", %{game: game}))

    {:shutdown, :left}
  end

  ###########
  # HELPERS #
  ###########

  defp atomize(string), do: String.to_atom(string)

  defp assign_player(socket) do
    player = Repo.get(Player, socket.assigns[:player_id])
    assign(socket, :player, player)
  end

  defp get_player_and_strip_params(%{"player" => player} = params) do
    {Player.by_name(player), Map.drop(params, ["player"])}
  end

  defp maybe_broadcast_update(:skip_update_message, _), do: :ok

  defp maybe_broadcast_update(game, socket) do
    broadcast!(socket, "update", PokerExWeb.GameView.render("game.json", %{game: game}))
  end

  defp save_private_game(:skip_update_message, _), do: :ok

  defp save_private_game(game, socket) do
    case socket.assigns.type do
      "private" ->
        # Should only hit the database in prod
        if Application.get_env(PokerEx, :should_update_after_poker_action) do
          PrivateRoom.get_room_and_store_state(
            game.game_id,
            game.phase,
            game
          )
        else
          :ok
        end

      _ ->
        :ok
    end
  end

  defp broadcast_action_message(player, action, params, socket) when action in @poker_actions do
    message =
      case action do
        "call" -> "#{player.name} called."
        "raise" -> "#{player.name} raised #{inspect(params["amount"])}."
        "fold" -> "#{player.name} folded."
        "check" -> "#{player.name} checked."
      end

    broadcast!(socket, "new_message", %{message: message})
  end

  defp broadcast_action_message(_, _, _, _), do: :ok
end
