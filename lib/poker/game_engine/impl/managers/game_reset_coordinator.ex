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
end
