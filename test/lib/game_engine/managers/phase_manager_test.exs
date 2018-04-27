defmodule PokerEx.PhaseManagerTest do
  use ExUnit.Case
  use PokerEx.EngineCase
  alias PokerEx.GameEngine.Impl, as: Engine
  alias PokerEx.GameEngine.{PhaseManager, ChipManager}

  describe "check_phase_change/3" do
    test "sets phase to :pre_flop when a second player joins" do
      seating = %{arrangement: [{"player_1", 0}, {"player_2", 1}]}

      engine =
        Engine.new()
        |> Map.put(:seating, seating)

      assert :pre_flop = PhaseManager.check_phase_change(engine, :join, seating)
    end

    test "does not change phase when the first player joins" do
      seating = %{arrangement: [{"player_1", 0}]}

      engine = Map.put(Engine.new(), :seating, seating)

      assert :idle = PhaseManager.check_phase_change(engine, :join, seating)
    end

    test "does not change phase on joins in betting rounds" do
      seating = %{arrangement: [{"player_1", 0}, {"player_2", 1}, {"player_3", 2}]}

      engine =
        Map.put(Engine.new(), :seating, seating)
        |> Map.put(:phase, :pre_flop)

      assert :pre_flop = PhaseManager.check_phase_change(engine, :join, seating)
    end

    test "does not change phases unless all active players have called", context do
      engine =
        Map.put(Engine.new(), :player_tracker, TestData.insert_active_players(context))
        |> Map.put(:phase, :pre_flop)
        |> Map.update(:player_tracker, %{}, fn tracker ->
          TestData.call_for_players(tracker, [context.p1, context.p2, context.p3])
        end)

      # ^^ Only half the players have called. Do not advance to next phase
      assert :pre_flop = PhaseManager.check_phase_change(engine, :bet, engine.player_tracker)
    end

    test "changes phase when the last active player calls", context do
      engine =
        Map.put(Engine.new(), :player_tracker, TestData.insert_active_players(context))
        |> Map.put(:phase, :pre_flop)
        |> Map.update(:player_tracker, %{}, fn tracker ->
          TestData.call_for_all(tracker, context)
        end)

      assert :flop = PhaseManager.check_phase_change(engine, :bet, engine.player_tracker)
    end

    test "changes phase to game_over if all players go all in", context do
      engine =
        Map.put(Engine.new(), :player_tracker, TestData.put_all_players_all_in(context))
        |> Map.put(:phase, :pre_flop)

      assert :game_over = PhaseManager.check_phase_change(engine, :bet, engine.player_tracker)
    end

    test "changes phase to game_over when there is one active player remaining", context do
      engine =
        Map.update(Engine.new(), :player_tracker, %{}, fn tracker ->
          Map.put(tracker, :active, [context.p1.name])
        end)
        |> Map.update(:player_tracker, %{}, fn tracker ->
          TestData.fold_for_all_but_first(tracker, context)
        end)
        |> Map.put(:phase, :pre_flop)

      assert :game_over = PhaseManager.check_phase_change(engine, :bet, engine.player_tracker)
    end

    test "changes phase to game_over with all_ins and one player active who called", context do
      engine =
        Map.update(Engine.new(), :player_tracker, %{}, fn tracker ->
          Map.put(tracker, :active, [context.p1.name])
        end)
        |> Map.update(:player_tracker, %{}, fn tracker ->
          TestData.all_in_for_all_but_first(tracker, context)
        end)
        |> Map.update(:player_tracker, %{}, fn tracker ->
          TestData.call_for_players(tracker, [context.p1])
        end)
        |> Map.put(:phase, :pre_flop)

      assert :game_over = PhaseManager.check_phase_change(engine, :bet, engine.player_tracker)
    end

    test "does not change phase to game_over with all_in and one player who did not call",
         context do
      engine =
        Map.update(Engine.new(), :player_tracker, %{}, fn tracker ->
          Map.put(tracker, :active, [context.p1.name])
        end)
        |> Map.update(:player_tracker, %{}, fn tracker ->
          TestData.all_in_for_all_but_first(tracker, context)
        end)
        |> Map.put(:phase, :pre_flop)

      assert :pre_flop = PhaseManager.check_phase_change(engine, :bet, engine.player_tracker)
    end

    test "changes phase to game over when all active players have called", %{p1: p1, p2: p2} do
      engine =
        Map.update(Engine.new(), :player_tracker, %{}, fn tracker ->
          Map.put(tracker, :active, [p1.name, p2.name])
        end)
        |> Map.update(:player_tracker, %{}, fn tracker ->
          TestData.call_for_players(tracker, [p1, p2])
        end)
        |> Map.put(:phase, :river)

      assert :game_over = PhaseManager.check_phase_change(engine, :bet, engine.player_tracker)
    end

    test "changes phase to game over when there are no more active players", context do
      engine = Engine.new() |> Map.put(:phase, :river)

      assert :game_over = PhaseManager.check_phase_change(engine, :bet, engine.player_tracker)
    end

    test "does not change phase unless all active players have called", %{p1: p1, p2: p2} do
      engine =
        Map.update(Engine.new(), :player_tracker, %{}, fn tracker ->
          Map.put(tracker, :active, [p1.name, p2.name])
        end)
        |> Map.update(:player_tracker, %{}, fn tracker ->
          TestData.call_for_players(tracker, [p1])
        end)
        |> Map.put(:phase, :river)

      assert :river = PhaseManager.check_phase_change(engine, :bet, engine.player_tracker)
    end

    test "changes phase to :idle if there is only one player seated", %{p1: p1} do
      engine =
        Map.update(Engine.new(), :seating, %{}, fn seating ->
          Map.put(seating, :arrangement, [{p1.name, 0}])
        end)
        |> Map.put(:phase, :between_rounds)

      assert :idle = PhaseManager.check_phase_change(engine, :system, engine.seating)
    end

    test "change phase to :pre_flop if there are two or more players seated", %{p1: p1, p2: p2} do
      engine =
        Map.update(Engine.new(), :seating, %{}, fn seating ->
          Map.put(seating, :arrangement, [{p1.name, 0}, {p2.name, 0}])
        end)
        |> Map.put(:phase, :between_rounds)

      assert :pre_flop = PhaseManager.check_phase_change(engine, :system, engine.seating)
    end
  end
end
