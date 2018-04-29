defmodule PokerEx.GameEngine.AsyncManagerTest do
  use ExUnit.Case
  use PokerEx.EngineCase
  alias PokerEx.GameEngine.Impl, as: Engine
  alias PokerEx.GameEngine.{AsyncManager}
  alias PokerEx.Player

  describe "mark_for_action/3" do
    test "marking a player to leave inserts active players in the fold queue", context do
      engine = Map.put(Engine.new(), :player_tracker, TestData.insert_active_players(context))

      async_data = AsyncManager.mark_for_action(engine, context.p1.name, :leave)
      assert context.p1.name in async_data.cleanup_queue
    end

    test "marking a player/chip combination for add chips inserts the data in the chip queue",
         context do
      engine = Map.put(Engine.new(), :player_tracker, TestData.insert_active_players(context))

      async_data = AsyncManager.mark_for_action(engine, context.p1.name, {:add_chips, 200})
      assert {context.p1.name, 200} in async_data.chip_queue
    end
  end

  describe "run/2" do
    test "auto folds for the active player if marked as leaving", context do
      engine =
        Map.put(Engine.new(), :player_tracker, TestData.insert_active_players(context))
        |> Map.update(:chips, %{}, fn _ -> TestData.add_200_chips_for_all(context) end)
        |> Map.update(:chips, %{}, fn chips ->
          Map.put(chips, :to_call, 10)
        end)

      # Since we marked the :to_call amount as 10 chips and the players have not
      # paid any chips in, the player should be auto-folded. If the player has paid
      # the :to_call amount, the async manager would auto-check for the player instead.
      # We also arbitrarily insert 200 chips into the player's chip_roll during the game
      # that are not taken from the player account (defaults to each player having 1000 chips)
      # total. When the player is removed from the game, they should be credited with what
      # remains in the chip_roll for them -- the amount will be added back to their account,
      # which is why we expect the new player record to have 1200 chips instead of 1000.

      async_data = AsyncManager.mark_for_action(engine, context.p1.name, :leave)
      engine = %Engine{engine | async_manager: async_data}
      assert {:ok, engine} = AsyncManager.run(engine, :cleanup)
      refute context.p1.name in engine.player_tracker.active
      assert context.p1.name in engine.player_tracker.folded
      refute context.p1.name in Enum.map(engine.seating.arrangement, fn {name, _} -> name end)
      assert Player.by_name(context.p1.name).chips == 1200
    end

    test "does not do anything if the player marked as leaving is not active", context do
      engine = Map.put(Engine.new(), :player_tracker, TestData.insert_active_players(context))

      async_data = AsyncManager.mark_for_action(engine, context.p2.name, :leave)
      engine = %Engine{engine | async_manager: async_data}
      assert {:ok, updated_engine} = AsyncManager.run(engine, :cleanup)
      assert updated_engine == engine
    end

    test "auto checks for the active player if marked as leaving", context do
      # This happens when the player has already paid the :to_call amount
      # but has not yet called.
      engine =
        Map.put(Engine.new(), :player_tracker, TestData.insert_active_players(context))
        |> Map.update(:chips, %{}, fn _ -> TestData.add_200_chips_for_all(context) end)
        |> Map.update(:chips, %{}, fn chips ->
          Map.update(chips, :round, %{}, fn round -> Map.put(round, context.p1.name, 10) end)
        end)
        |> Map.update(:chips, %{}, fn chips -> Map.put(chips, :to_call, 10) end)

      async_data = AsyncManager.mark_for_action(engine, context.p1.name, :leave)
      engine = %Engine{engine | async_manager: async_data}
      assert {:ok, engine} = AsyncManager.run(engine, :cleanup)
      assert context.p1.name in engine.player_tracker.called
    end
  end
end
