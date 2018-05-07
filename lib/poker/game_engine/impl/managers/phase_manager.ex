defmodule PokerEx.GameEngine.PhaseManager do
  alias PokerEx.GameEngine.{ChipManager, PlayerTracker, Seating}
  alias PokerEx.GameEngine.Impl, as: Engine
  @type action :: :join | :leave | :bet | :system
  @type reference_module :: PlayerTracker.t() | Seating.t()
  @non_betting_phases [:idle, :between_rounds]
  @betting_phases [:pre_flop, :flop, :turn, :river]

  @spec maybe_change_phase(PokerEx.GameEngine.Impl.t()) :: PokerEx.GameEngine.Impl.t()
  def maybe_change_phase(%{phase: :idle} = engine) do
    case length(engine.seating.arrangement) >= 2 do
      true ->
        %PokerEx.GameEngine.Impl{
          engine
          | phase: :pre_flop,
            chips: ChipManager.post_blinds(engine)
        }

      false ->
        engine
    end
  end

  def maybe_change_phase(engine), do: engine

  @doc """
  Determines whether or not to change the game's phase.
  """
  @spec check_phase_change(Engine.t(), action, reference_module) :: Engine.phase()
  def check_phase_change(%{phase: phase}, :join, seating) when phase in @non_betting_phases do
    case length(seating.arrangement) > 1 do
      true -> :pre_flop
      false -> :idle
    end
  end

  def check_phase_change(%{phase: phase}, :join, _), do: phase

  def check_phase_change(%{phase: phase}, :bet, player_tracker) when phase in @betting_phases do
    with true <- length(player_tracker.active) >= 1 do
      case length(player_tracker.active) == length(player_tracker.called) do
        true ->
          if length(player_tracker.active) == 1, do: :game_over, else: next_phase(phase)

        false ->
          cond do
            length(player_tracker.all_in) >= 1 && length(player_tracker.active) == 1 ->
              phase

            length(player_tracker.active) == 1 ->
              :game_over

            true ->
              phase
          end
      end
    else
      _ ->
        :game_over
    end
  end

  def check_phase_change(engine, :bet, _player_tracker), do: engine.phase

  def check_phase_change(%{phase: :between_rounds}, :system, seating) do
    case length(seating.arrangement) > 1 do
      true -> :pre_flop
      false -> :idle
    end
  end

  defp next_phase(:idle), do: :pre_flop
  defp next_phase(:pre_flop), do: :flop
  defp next_phase(:flop), do: :turn
  defp next_phase(:turn), do: :river
  defp next_phase(:river), do: :game_over
end
