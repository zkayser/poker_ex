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

  def terminate(_reason, %Game{type: :public, chips: %{chip_roll: chip_roll}})
      when is_map(chip_roll) do
    Logger.warn("Terminating public game and restoring chips to players")
    restore_chips_to_players(chip_roll)
  end

  def terminate(:manual, %Game{chips: %{chip_roll: chip_roll}}) when is_map(chip_roll) do
    restore_chips_to_players(chip_roll)
  end

  def terminate(reason, %Game{type: :private, game_id: id} = game) do
    Logger.warn("Now terminating #{inspect(id)} for reason: #{inspect(reason)}.")
    Logger.warn("Storing game state...")
    # PrivateRoom.get_room_and_store_state/3 is out of date with the move from
    # 	gen_statem to GenServer. The second parameter used to store the phase of
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
    with {:ok, game_update} <- Game.fold(game, player) do
      {:reply, game_update, game_update}
    else
      {:error, error} ->
        {:reply, error, game}
    end
  end

  #### TODO: Add in the remaining callbacks -- player_count and player_list

  ###########
  # HELPERS #
  ###########

  defp restore_chips_to_players(chip_roll) do
    chip_roll
    |> Map.keys()
    |> Enum.each(fn p -> Player.update_chips(p, chip_roll[p]) end)
  end
end
