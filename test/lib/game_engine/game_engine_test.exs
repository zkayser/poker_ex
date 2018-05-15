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

  describe "calls" do
    test "players cannot call out of turn", context do
      engine = TestData.setup_multiplayer_game(context)

      # The first turn belongs to player 4 (context.p4)
      assert {:error, :out_of_turn} = Game.call(engine, context.p5.name)
    end

    test "when the active player calls, the active list rotates", context do
      engine = TestData.setup_multiplayer_game(context)

      assert {:ok, engine} = Game.call(engine, context.p4.name)
      assert hd(engine.player_tracker.active) == context.p5.name
      assert context.p4.name in engine.player_tracker.called
    end

    test "the phase should change when all players call", context do
      players = [context.p4, context.p5, context.p6, context.p1, context.p2, context.p3]
      engine = TestData.setup_multiplayer_game(context)

      {:ok, engine} =
        Enum.reduce(players, {:ok, engine}, fn player, {:ok, engine} ->
          Game.call(engine, player.name)
        end)

      assert engine.phase == :flop
    end

    test "the called list should be cleared when all players call and phase changes", context do
      players = [context.p4, context.p5, context.p6, context.p1, context.p2, context.p3]
      engine = TestData.setup_multiplayer_game(context)

      {:ok, engine} =
        Enum.reduce(players, {:ok, engine}, fn player, {:ok, engine} ->
          Game.call(engine, player.name)
        end)

      assert [] = engine.player_tracker.called
    end

    test "each player's call gets added to the amount of chips in the pot", context do
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

  describe "checks" do
    test "players cannot check unless they have paid the to_call amount", context do
      engine = TestData.setup_multiplayer_game(context)
      assert {:error, :not_paid} = Game.check(engine, context.p4.name)
    end

    test "players can check once the to_call amount has been paid", context do
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

    test "players cannot check out of turn", context do
      engine = TestData.setup_multiplayer_game(context)

      assert {:error, :out_of_turn} = Game.check(engine, context.p3.name)
    end
  end
end
