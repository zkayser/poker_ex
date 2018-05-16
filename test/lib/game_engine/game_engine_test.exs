defmodule PokerEx.GameEngine.ImplTest do
  use ExUnit.Case
  use PokerEx.EngineCase
  alias PokerEx.GameEngine.Impl, as: Game

  @moduledoc """
  The number of operations you can make on an GameEngine.Impl
  is relatively limited, but are managed by sub-modules working
  together. The tests in this module more closely resemble integration
  tests in the sense that they ensure each of the sub-modules that
  carry out the work of the operations work together and exhibit
  expected behavior.
  """

  describe "call/2" do
    test "does not allow players to call out of turn", context do
      engine = TestData.setup_multiplayer_game(context)

      # The first turn belongs to player 4 (context.p4)
      assert {:error, :out_of_turn} = Game.call(engine, context.p5.name)
    end

    test "rotates the active list when the active player calls", context do
      engine = TestData.setup_multiplayer_game(context)

      assert {:ok, engine} = Game.call(engine, context.p4.name)
      assert hd(engine.player_tracker.active) == context.p5.name
      assert context.p4.name in engine.player_tracker.called
    end

    test "changes phase once all players have called", context do
      players = [context.p4, context.p5, context.p6, context.p1, context.p2, context.p3]
      engine = TestData.setup_multiplayer_game(context)

      {:ok, engine} =
        Enum.reduce(players, {:ok, engine}, fn player, {:ok, engine} ->
          Game.call(engine, player.name)
        end)

      assert engine.phase == :flop
    end

    test "clears the called list once all players have called", context do
      players = [context.p4, context.p5, context.p6, context.p1, context.p2, context.p3]
      engine = TestData.setup_multiplayer_game(context)

      {:ok, engine} =
        Enum.reduce(players, {:ok, engine}, fn player, {:ok, engine} ->
          Game.call(engine, player.name)
        end)

      assert [] = engine.player_tracker.called
    end

    test "adds the to_call amount to the overall pot value", context do
      players = [context.p4, context.p5, context.p6, context.p1, context.p2, context.p3]
      engine = TestData.setup_multiplayer_game(context)

      {:ok, engine} =
        Enum.reduce(players, {:ok, engine}, fn player, {:ok, engine} ->
          Game.call(engine, player.name)
        end)

      # The big blind is defaulted to 10. If 6 players call, then 6 * 10 = 60.
      assert 60 = engine.chips.pot
    end
  end

  describe "check/2" do
    test "requires players to pay the to_call amount", context do
      engine = TestData.setup_multiplayer_game(context)
      assert {:error, :not_paid} = Game.check(engine, context.p4.name)
    end

    test "allows checks once a player has paid the to_call amount", context do
      engine =
        TestData.setup_multiplayer_game(context)
        |> Map.update(:chips, %{}, fn chips ->
          Map.update(chips, :round, %{}, fn round ->
            Map.put(round, context.p4.name, 10)
          end)
        end)

      assert {:ok, engine} = Game.check(engine, context.p4.name)
      assert hd(engine.player_tracker.active) == context.p5.name
    end

    test "prevents players from taking action out of turn", context do
      engine = TestData.setup_multiplayer_game(context)

      assert {:error, :out_of_turn} = Game.check(engine, context.p3.name)
    end
  end

  describe "raise/3" do
    test "falls back to the call/2 implementation if the raise amount is < to_call", context do
      engine = TestData.setup_multiplayer_game(context)

      assert {:ok, engine} = Game.raise(engine, context.p4.name, 5)
      assert engine.chips.round[context.p4.name] == 10
      assert engine.chips.to_call == 10
      assert context.p4.name in engine.player_tracker.called
    end

    test "sets the to_call amount to the value of the raise", context do
      engine = TestData.setup_multiplayer_game(context)

      assert {:ok, engine} = Game.raise(engine, context.p4.name, 100)
      assert engine.chips.round[context.p4.name] == 100
      assert engine.chips.to_call == 100
      assert [] = engine.player_tracker.called
      assert context.p5.name == hd(engine.player_tracker.active)
    end

    test "places the raising player in the all_in list if the raise amount is > player chips",
         context do
      engine = TestData.setup_multiplayer_game(context)

      # Players only start with 200 given the setup function above
      assert {:ok, engine} = Game.raise(engine, context.p4.name, 250)
      assert context.p4.name in engine.player_tracker.all_in
      assert engine.chips.to_call == 200
      refute context.p4.name in engine.player_tracker.active
    end

    test "clears out the called list if a new to_call amount is set", context do
      engine =
        TestData.setup_multiplayer_game(context)
        |> Map.update(:player_tracker, %{}, fn tracker ->
          # Arbitrarily place some players in the called list
          Map.put(tracker, :called, [context.p1.name, context.p2.name])
        end)

      assert {:ok, engine} = Game.raise(engine, context.p4.name, 20)
      assert [] = engine.player_tracker.called
    end
  end
end
