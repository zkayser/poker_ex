defmodule PokerEx.GameResetCoordinatorTest do
  use ExUnit.Case
  use PokerEx.EngineCase
  alias PokerEx.GameEngine.Impl, as: Engine
  alias PokerEx.GameEngine.GameResetCoordinator

  describe "coordinate_reset/1" do
    test "cycles the seating arrangement", context do
      engine = Map.put(Engine.new(), :seating, TestData.seat_players(context))

      assert new_engine = GameResetCoordinator.coordinate_reset(engine)
      assert hd(engine.seating.arrangement) == List.last(new_engine.seating.arrangement)
    end

    test "removes players with no remaining chips from the chip roll and seating arrangement",
         context do
      engine =
        Map.put(Engine.new(), :seating, TestData.seat_players(context))
        |> Map.put(:player_tracker, TestData.insert_active_players(context))
        |> Map.put(:chips, TestData.add_200_chips_for_all(context))
        |> Map.update(:chips, %{}, fn chips ->
          Map.update(chips, :chip_roll, %{}, fn chip_roll ->
            Map.put(chip_roll, context.p1.name, 0)
          end)
        end)

      assert engine = GameResetCoordinator.coordinate_reset(engine)
      refute engine.chips.chip_roll[context.p1.name]
      refute context.p1.name in Enum.map(engine.seating.arrangement, fn {player, _} -> player end)
    end

    test "sets the active list based on the seating arrangement", context do
      engine =
        Map.put(Engine.new(), :seating, TestData.seat_players(context))
        |> Map.put(:player_tracker, TestData.insert_active_players(context))

      assert new_engine = GameResetCoordinator.coordinate_reset(engine)
      assert hd(engine.seating.arrangement) == List.last(new_engine.seating.arrangement)
      assert hd(new_engine.player_tracker.active) == context.p2.name
      # Assert p2 is head of active list because p1 should be shifted to from the front
      # to the back when the game is reset, putting p2 at the front of the active list
      assert new_engine.roles.dealer == 1
      assert new_engine.roles.big_blind == 3
      assert new_engine.roles.small_blind == 2
    end
  end
end
