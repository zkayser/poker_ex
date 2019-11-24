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
      assert {:error, :out_of_turn} = Game.call(engine, context.p5)
    end

    test "rotates the active list when the active player calls", context do
      engine = TestData.setup_multiplayer_game(context)

      assert {:ok, engine} = Game.call(engine, context.p4)
      assert hd(engine.player_tracker.active) == context.p5
      assert context.p4.name in engine.player_tracker.called
    end

    test "changes phase once all players have called", context do
      players = [context.p4, context.p5, context.p6, context.p1, context.p2, context.p3]
      engine = TestData.setup_multiplayer_game(context)

      {:ok, engine} =
        Enum.reduce(players, {:ok, engine}, fn player, {:ok, engine} ->
          Game.call(engine, player)
        end)

      assert engine.phase == :flop
    end

    test "clears the called list once all players have called", context do
      players = [context.p4, context.p5, context.p6, context.p1, context.p2, context.p3]
      engine = TestData.setup_multiplayer_game(context)

      {:ok, engine} =
        Enum.reduce(players, {:ok, engine}, fn player, {:ok, engine} ->
          Game.call(engine, player)
        end)

      assert [] = engine.player_tracker.called
    end

    test "adds the to_call amount to the overall pot value", context do
      players = [context.p4, context.p5, context.p6, context.p1, context.p2, context.p3]
      engine = TestData.setup_multiplayer_game(context)

      {:ok, engine} =
        Enum.reduce(players, {:ok, engine}, fn player, {:ok, engine} ->
          Game.call(engine, player)
        end)

      # The big blind is defaulted to 10. If 6 players call, then 6 * 10 = 60.
      assert 60 = engine.chips.pot
    end
  end

  describe "check/2" do
    test "requires players to pay the to_call amount", context do
      engine = TestData.setup_multiplayer_game(context)
      assert {:error, :not_paid} = Game.check(engine, context.p4)
    end

    test "allows checks once a player has paid the to_call amount", context do
      engine =
        TestData.setup_multiplayer_game(context)
        |> Map.update(:chips, %{}, fn chips ->
          Map.update(chips, :round, %{}, fn round ->
            Map.put(round, context.p4.name, 10)
          end)
        end)

      assert {:ok, engine} = Game.check(engine, context.p4)
      assert hd(engine.player_tracker.active) == context.p5
    end

    test "prevents players from taking action out of turn", context do
      engine = TestData.setup_multiplayer_game(context)

      assert {:error, :out_of_turn} = Game.check(engine, context.p3)
    end
  end

  describe "raise/3" do
    test "falls back to the call/2 implementation if the raise amount is < to_call", context do
      engine = TestData.setup_multiplayer_game(context)

      assert {:ok, engine} = Game.raise(engine, context.p4, 5)
      assert engine.chips.round[context.p4.name] == 10
      assert engine.chips.to_call == 10
      assert context.p4.name in engine.player_tracker.called
    end

    test "sets the to_call amount to the value of the raise", context do
      engine = TestData.setup_multiplayer_game(context)

      assert {:ok, engine} = Game.raise(engine, context.p4, 100)
      assert engine.chips.round[context.p4.name] == 100
      assert engine.chips.to_call == 100
      assert [] = engine.player_tracker.called
      assert context.p5 == hd(engine.player_tracker.active)
    end

    test "places the raising player in the all_in list if the raise amount is > player chips",
         context do
      engine = TestData.setup_multiplayer_game(context)

      # Players only start with 200 given the setup function above
      assert {:ok, engine} = Game.raise(engine, context.p4, 250)
      assert context.p4.name in engine.player_tracker.all_in
      assert engine.chips.to_call == 200
      refute context.p4 in engine.player_tracker.active
    end

    test "clears out the called list if a new to_call amount is set", context do
      engine =
        TestData.setup_multiplayer_game(context)
        |> Map.update(:player_tracker, %{}, fn tracker ->
          # Arbitrarily place some players in the called list
          Map.put(tracker, :called, [context.p1.name, context.p2.name])
        end)

      assert {:ok, engine} = Game.raise(engine, context.p4, 20)
      assert [] = engine.player_tracker.called
    end
  end

  describe "fold/2" do
    test "places the folding player in the folded list and removes them from active", context do
      engine = TestData.setup_multiplayer_game(context)

      assert {:ok, engine} = Game.fold(engine, context.p4)
      assert context.p4.name in engine.player_tracker.folded
      refute context.p4 in engine.player_tracker.active
    end

    test "prevents players from taking action out of turn", context do
      engine = TestData.setup_multiplayer_game(context)

      assert {:error, :out_of_turn} = Game.fold(engine, context.p5)
    end

    test "ends the game if everyone folds except one player who has paid the to_call amount",
         context do
      engine =
        TestData.setup_multiplayer_game(context)
        |> Map.update(:player_tracker, %{}, fn tracker ->
          Map.update(tracker, :folded, [], fn _folded ->
            # Fold all but the second-to-last and last players to go in the round
            [context.p4.name, context.p5.name, context.p6.name, context.p1.name]
          end)
          |> Map.update(:active, [], fn _active ->
            [context.p2, context.p3]
          end)
        end)
        |> Map.put(:phase, :flop)

      # Put the game in the :flop phase so we can assert that the game state was reset to :pre_flop
      # on game over
      assert {:ok, engine} = Game.fold(engine, context.p2)
      assert engine.phase == :pre_flop
      assert length(engine.player_tracker.active) == 6
      assert [] = engine.player_tracker.folded
      # Game over bookkeeping. The blinds should have changed and the active
      # list reset
      refute context.p4 == hd(engine.player_tracker.active)
      assert context.p5 == hd(engine.player_tracker.active)
      assert engine.roles.dealer == 1
      assert engine.roles.small_blind == 2
      assert engine.roles.big_blind == 3
    end

    test "ends the game if the final player folds and two or more players are all in", context do
      engine =
        TestData.setup_multiplayer_game(context)
        |> Map.update(:player_tracker, %{}, fn tracker ->
          Map.update(tracker, :all_in, [], fn _ -> [context.p4.name, context.p5.name] end)
          |> Map.update(:active, [], fn _active ->
            [context.p6, context.p1, context.p2, context.p3]
          end)
        end)
        |> Map.put(:phase, :flop)
        |> Map.update(:chips, %{}, fn chips ->
          # Seed the paid amount and chips for the all in players,
          # otherwise an arithmetic exception will be raised when
          # trying to reward the winning player(s).
          # The numbers below are arbitrary.
          Map.put(chips, :paid, %{context.p4.name => 100, context.p5.name => 100})
          |> Map.put(:round, %{context.p4.name => 100, context.p5.name => 100})
        end)

      assert {:ok, engine} =
               Enum.reduce(engine.player_tracker.active, {:ok, engine}, fn player,
                                                                           {:ok, engine} ->
                 Game.fold(engine, player)
               end)

      assert engine.phase == :pre_flop
    end
  end

  describe "leave/2" do
    test "auto-folds if the player is leaving", context do
      engine = TestData.setup_multiplayer_game(context)

      assert {:ok, engine} = Game.leave(engine, context.p4)
      refute context.p4 in engine.player_tracker.active
      assert context.p4.name in engine.player_tracker.folded
      refute context.p4 in Enum.map(engine.seating.arrangement, fn {player, _} -> player end)
    end

    test "credits auto-folding players with the chips they have remaining in the game", context do
      engine = TestData.setup_multiplayer_game(context)

      assert {:ok, _engine} = Game.leave(engine, context.p4)
      # Players are credited 1,000 chips on creation and each player
      # is given 200 extra chips in the setup_multiplayer_game/1 function above.
      # Given these conditions, a leaving player should now have 1200 chips.
      assert PokerEx.Player.by_name(context.p4.name).chips == 1200
    end

    test "credits leaving players with chips remaining in the :idle and :between_rounds phases",
         context do
      engine =
        TestData.setup_multiplayer_game(context)
        |> Map.put(:phase, :idle)

      assert {:ok, engine} = Game.leave(engine, context.p4)
      assert PokerEx.Player.by_name(context.p4.name).chips == 1200
      refute context.p4 in Enum.map(engine.seating.arrangement, fn {player, _} -> player end)
    end

    test "auto-checks for the player if the leaving player has paid the to_call amount",
         context do
      engine =
        TestData.setup_multiplayer_game(context)
        |> Map.update(:chips, %{}, fn chips ->
          Map.put(chips, :round, %{context.p4.name => 10})
        end)

      assert {:ok, engine} = Game.leave(engine, context.p4)
      assert context.p4.name in engine.player_tracker.called
      assert context.p4 in engine.async_manager.cleanup_queue
      assert context.p4 in Enum.map(engine.seating.arrangement, fn {player, _} -> player end)
    end

    test "places the player in the cleanup queue and auto-folds when player is active", context do
      engine = TestData.setup_multiplayer_game(context)

      assert {:ok, engine} = Game.leave(engine, context.p5)
      assert context.p5 in engine.async_manager.cleanup_queue
      refute context.p5.name in engine.player_tracker.folded
      assert context.p5 in Enum.map(engine.seating.arrangement, fn {player, _} -> player end)

      assert {:ok, engine} = Game.fold(engine, context.p4)
      assert context.p5.name in engine.player_tracker.folded
      refute context.p5 in Enum.map(engine.seating.arrangement, fn {player, _} -> player end)
      refute context.p5 in engine.player_tracker.active
    end
  end

  describe "add_chips/3" do
    test "places the player in the add_chip queue until game over", context do
      engine = TestData.setup_multiplayer_game(context)

      assert {:ok, engine} = Game.add_chips(engine, context.p4, 200)
      assert {context.p4, 200} in engine.async_manager.chip_queue
      # Does not add the chips to the chip_roll automatically
      # Players begin with 200 chips given the TestData setup above,
      # so adding another 200 should put the player at 400 chips
      assert engine.chips.chip_roll[context.p4.name] == 200
    end

    test "adds the chip amount in the queue to the chip_roll on game over", context do
      players = [
        context.p4,
        context.p5,
        context.p6,
        context.p1,
        context.p2
      ]

      engine = TestData.setup_multiplayer_game(context)

      assert {:ok, engine} = Game.add_chips(engine, context.p5, 200)

      assert {:ok, engine} =
               Enum.reduce(players, {:ok, engine}, fn player, {:ok, engine} ->
                 Game.fold(engine, player)
               end)

      assert engine.chips.chip_roll[context.p5.name] == 400
    end
  end
end
