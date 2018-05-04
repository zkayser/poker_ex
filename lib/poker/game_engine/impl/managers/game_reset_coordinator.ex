defmodule PokerEx.GameEngine.GameResetCoordinator do
  alias PokerEx.GameEngine.{Seating, ChipManager, PlayerTracker, RoleManager}

  @spec coordinate_reset(PokerEx.GameEngine.Impl.t()) :: PokerEx.GameEngine.Impl.t()
  def coordinate_reset(engine) do
    new_seating = update_seating(engine)

    %{
      engine
      | seating: new_seating,
        chips: ChipManager.reset_game(engine.chips),
        player_tracker: update_player_tracker(engine),
        roles: RoleManager.manage_roles(%{seating: new_seating, roles: engine.roles})
    }
    |> PlayerTracker.set_active_players(:game_over)
    |> Map.put(:phase, update_phase(engine))
    |> maybe_post_blind()
  end

  defp get_players_to_remove(engine) do
    for {key, value} <- engine.chips.chip_roll, value == 0, do: key
  end

  defp update_seating(engine) do
    %{
      seating: %{
        engine.seating
        | arrangement:
            Enum.reject(engine.seating.arrangement, fn {player, _} ->
              player in get_players_to_remove(engine)
            end)
      }
    }
    |> Seating.cycle()
  end

  defp update_phase(engine) do
    if length(engine.seating.arrangement) > 1, do: :pre_flop, else: :between_rounds
  end

  defp update_player_tracker(engine) do
    %{engine.player_tracker | all_in: [], called: [], folded: []}
  end

  defp maybe_post_blind(%{phase: :pre_flop} = engine) do
    {:ok, chips_after_posting} = ChipManager.post_blinds(engine)
    cycle_for_dealer = PlayerTracker.cycle(engine)
    cycle_for_small_blind = PlayerTracker.cycle(%{player_tracker: cycle_for_dealer})
    cycle_for_big_blind = PlayerTracker.cycle(%{player_tracker: cycle_for_small_blind})
    updated_tracker = position_blinds_in_tracker(chips_after_posting, cycle_for_big_blind, engine)
    %{engine | player_tracker: updated_tracker, chips: chips_after_posting}
  end

  defp maybe_post_blind(engine), do: engine

  defp position_blinds_in_tracker(chips, tracker, engine) do
    big_blind =
      Enum.find(engine.seating.arrangement, fn {_, seat_num} ->
        seat_num == engine.roles.big_blind
      end)

    small_blind =
      Enum.find(engine.seating.arrangement, fn {_, seat_num} ->
        seat_num == engine.roles.small_blind
      end)

    cond do
      chips.chip_roll[small_blind] == 0 && chips.chip_roll[big_blind] == 0 ->
        %{tracker | all_in: [big_blind, small_blind]}

      chips.chip_roll[small_blind] == 0 ->
        %{tracker | all_in: [small_blind], called: [big_blind]}

      true ->
        %{tracker | called: [big_blind]}
    end
  end
end
