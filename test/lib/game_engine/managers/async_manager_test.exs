defmodule PokerEx.GameEngine.AsyncManagerTest do
  use ExUnit.Case
  use PokerEx.EngineCase
  alias PokerEx.GameEngine.Impl, as: Engine
  alias PokerEx.GameEngine.{AsyncManager}

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
end
