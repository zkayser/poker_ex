defmodule PokerEx.GameEngine.GameResetCoordinator do
  alias PokerEx.Events

  alias PokerEx.GameEngine.{
    Seating,
    ChipManager,
    PlayerTracker,
    RoleManager,
    ScoreManager,
    CardManager
  }

  @spec coordinate_reset(PokerEx.GameEngine.Impl.t()) :: PokerEx.GameEngine.Impl.t()
  def coordinate_reset(engine) do
    scoring = ScoreManager.manage_score(engine)
    new_chips = %{engine.chips | chip_roll: reward_winners(engine.chips.chip_roll, scoring)}
    new_seating = update_seating(%{engine | chips: new_chips})
    engine = %{engine | chips: new_chips}
    {:ok, new_cards} = CardManager.deal(%{cards: %CardManager{}, seating: new_seating}, :pre_flop)

    %{
      engine
      | seating: new_seating,
        chips: ChipManager.reset_game(engine.chips),
        cards: new_cards,
        player_tracker: update_player_tracker(engine),
        scoring: %ScoreManager{},
        roles: RoleManager.manage_roles(%{seating: new_seating, roles: engine.roles})
    }
    |> PlayerTracker.set_active_players(:game_over)
    |> Map.put(:phase, update_phase(%{engine | seating: new_seating}))
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
    case length(engine.seating.arrangement) > 1 do
      true ->
        :pre_flop

      false ->
        Events.clear_ui(engine.game_id)
        :between_rounds
    end
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

  defp reward_winners(chip_roll, %{rewards: rewards}) do
    Enum.reduce(rewards, chip_roll, fn {player, reward}, acc ->
      Map.update(acc, player, 0, fn player_chips -> player_chips + reward end)
    end)
  end

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
        %{tracker | all_in: [small_blind]}

      true ->
        tracker
    end
  end
end
