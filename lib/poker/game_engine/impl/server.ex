defmodule PokerEx.GameEngine.Server do
  use GenServer
  require Logger
  alias PokerEx.GameEngine.Impl, as: Game
  alias PokerEx.Player

  ##################
  # INITIALIZATION #
  ##################

  def init([]), do: {:ok, %Game{}}
  def init([[id, :private]]), do: {:ok, %Game{type: :private, game_id: id}}
  def init([id]), do: {:ok, %Game{game_id: id}}

  ###############
  # TERMINATION #
  ###############

  def terminate(:normal, %Game{type: :public}), do: :void

  def terminate(_reason, %Game{type: :public, chips: chips}) when is_map(chips) do
    Logger.warn("Terminating public game and restoring chips to players")
    restore_chips_to_players(chips)
  end

  def terminate(:manual, %Game{chips: chips}) when is_map(chips) do
    restore_chips_to_players(chips)
  end

  def terminate(reason, %Game{type: :private, game_id: id} = game) do
    Logger.warn("Now terminating #{inspect(id)} for reason: #{inspect(reason)}.")
    Logger.warn("Storing game state...")
    # PrivateRoom.get_room_and_store_state/3 is out of date with the move from
    # gen_statem to GenServer. The second parameter did store the phase of
    # the game (:pre_flop, :flop, etc.). This is now stored in the game struct,
    # so is no longer needed.
    PokerEx.PrivateRoom.get_room_and_store_state(id, nil, game)
    :void
  end

  def terminate(_, _), do: :void

  #############
  # CALLBACKS #
  #############

  def handle_call({:join, player, join_amount}, _from, game) do
    with {:ok, game_update} <- Game.join(game, player, join_amount) do
      {:reply, game_update, game_update}
    else
      {:error, error} ->
        {:reply, error, game}
    end
  end

  def handle_call({:call, player}, _from, game) do
    with {:ok, game_update} <- Game.call(game, player) do
      {:reply, game_update, game_update}
    else
      {:error, error} ->
        {:reply, error, game}
    end
  end

  def handle_call({:check, player}, _from, game) do
    with {:ok, game_update} <- Game.check(game, player) do
      {:reply, game_update, game_update}
    else
      {:error, error} ->
        {:reply, error, game}
    end
  end

  def handle_call({:raise, player, amount}, _from, game) do
    with {:ok, game_update} <- Game.raise(game, player, amount) do
      {:reply, game_update, game_update}
    else
      {:error, error} ->
        {:reply, error, game}
    end
  end

  def handle_call({:fold, player}, _from, game) do
    with {:ok, game_update} <- Game.fold(game, player) do
      {:reply, game_update, game_update}
    else
      {:error, error} ->
        {:reply, error, game}
    end
  end

  def handle_call({:leave, player}, _from, game) do
    with {:ok, game_update} <- Game.leave(game, player) do
      {:reply, game_update, game_update}
    else
      {:error, error} ->
        {:reply, error, game}
    end
  end

  def handle_call({:add_chips, player, amount}, _from, game) do
    with {:ok, game_update} <- Game.add_chips(game, player, amount) do
      {:reply, game_update, game_update}
    else
      {:error, error} ->
        {:reply, error, game}
    end
  end

  def handle_call(:no_op, _from, game), do: {:reply, game, game}

  def handle_call({:put_state, new_game}, _from, _game) do
    {:reply, new_game, new_game}
  end

  def handle_call(:player_count, _from, game), do: {:reply, Game.player_count(game), game}
  def handle_call(:player_list, _from, game), do: {:reply, Game.player_list(game), game}

  ###########
  # HELPERS #
  ###########

  defp restore_chips_to_players(chips) do
    chips
    |> Map.keys()
    |> Enum.each(fn p -> Player.update_chips(p, restore_chips(chips, p)) end)
  end

  defp restore_chips(%{chip_roll: chip_roll, paid: paid}, player) do
    case paid[player] do
      nil -> chip_roll[player]
      amount -> chip_roll[player] + amount
    end
  end
end
