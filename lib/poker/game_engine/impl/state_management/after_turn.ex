defmodule PokerEx.GameEngine.AfterTurn do
  alias PokerEx.GameEngine.{
    AsyncManager,
    PhaseManager,
    GameState,
    GameResetCoordinator,
    ChipManager,
    PlayerTracker
  }

  @moduledoc """
  This module exposes functions that operate on
  `PokerEx.GameEngine.Impl` structs to clean up
  after a player takes a turn and handle any
  asynchronous works that needs to be run prior
  to moving on to the next turn or phase of a
  poker game.
  """

  @type async_action :: :process_async_auto_actions | :maybe_reset_game | :cleanup_round
  @type return_value :: {:ok, PokerEx.GameEngine.Impl.t()}

  @doc """
  Pipes a `PokerEx.GameEngine.Impl` struct through a series
  of post-processing steps after a player has taken a turn.
  """
  @spec process({:ok, PokerEx.GameEngine.Impl.t()}, PokerEx.GameEngine.Impl.phase()) ::
          return_value
  def process(engine, initial_phase) do
    engine
    |> run(:process_async_auto_actions)
    |> run(:cleanup_round, initial_phase)
    |> run(:maybe_reset_game)
  end

  @doc """
  Removes any players that have been marked
  to leave and updates the phase if appropriate.
  Also handles the case in which the leaving player is active.
  This will auto-fold or auto-check for leaving players.
  """
  @spec run({:ok, PokerEx.GameEngine.Impl.t()}, async_action) :: return_value
  def run(
        {:ok, %{async_manager: %{cleanup_queue: []}} = engine},
        :process_async_auto_actions
      ) do
    {:ok, engine}
  end

  def run({:ok, %{phase: initial_phase} = engine}, :process_async_auto_actions) do
    with {:ok, engine} <- AsyncManager.run(engine, :cleanup),
         phase <- PhaseManager.check_phase_change(engine, :bet, engine.player_tracker) do
      {:ok,
       GameState.update(engine, [
         {:maybe_update_cards, initial_phase, phase},
         {:update_phase, phase}
       ])}
    else
      error -> error
    end
  end

  @doc """
  Resets the game engine implementation struct to a
  clean state and prepares for a new game only if the phase is :game_over.
  """
  def run({:ok, %{phase: :game_over} = engine}, :maybe_reset_game) do
    {:ok, GameResetCoordinator.coordinate_reset(engine)}
  end

  def run({:ok, engine}, _), do: {:ok, engine}

  @doc """
  Triggers any necessary cleanup after transitioning
  from one phase to the next. If there is no phase transition, then this
  clause is effectively a no-op.
  """
  @spec run(:ok, PokerEx.GameEngine.Impl.t(), PokerEx.GameEngine.Impl.phase()) :: return_value
  def(
    run({:ok, %{phase: current_phase} = engine}, :cleanup_round, initial_phase)
    when current_phase != initial_phase
  ) do
    {:ok, reset_round(engine)}
  end

  def run({:ok, engine}, :cleanup_round, _), do: {:ok, engine}

  @doc """
  Resets the `PokerEx.GameEngine.Impl` struct to a clean
  round state.
  """
  @spec reset_round(PokerEx.GameEngine.Impl.t()) :: PokerEx.GameEngine.Impl.t()
  def reset_round(engine) do
    %PokerEx.GameEngine.Impl{
      engine
      | chips: ChipManager.reset_round(engine.chips),
        player_tracker: PlayerTracker.reset_round(engine.player_tracker)
    }
  end
end
