defmodule PokerEx.GameEngineTest do
  use ExUnit.Case
  use PokerEx.EngineCase
  alias PokerEx.GameEngine.Impl, as: Engine
  alias PokerEx.GameEngine.{Seating}
  alias PokerEx.TestData
  @join_amount 200

  describe "join/3" do
    test "lets players join and places them in a seat", %{p1: p1} do
      name = p1.name
      assert {:ok, engine} = Engine.join(Engine.new(), p1, @join_amount)
      assert {p1.name, 0} in engine.seating.arrangement
      refute p1.name in engine.player_tracker.active
      assert %{^name => @join_amount} = engine.chips.chip_roll
    end

    test "transitions from :idle to :pre_flop when a second player joins", %{p1: p1, p2: p2} do
      {:ok, engine} = Engine.join(Engine.new(), p1, @join_amount)
      assert {:ok, engine} = Engine.join(engine, p2, @join_amount)
      assert engine.phase == :pre_flop
      assert p1.name in engine.player_tracker.active
      assert p2.name in engine.player_tracker.active
      assert {p2.name, 1} == engine.seating.current_big_blind
      assert {p1.name, 0} == engine.seating.current_small_blind
    end

    test "returns an error when player joins with fewer than 100 chips", %{p1: p1} do
      engine = Engine.new()
      assert {:error, :join_amount_insufficient} = Engine.join(engine, p1, 95)
      assert {:error, :join_amount_insufficient} = Engine.join(engine, p1, 0)
      assert {:error, :join_amount_insufficient} = Engine.join(engine, p1, -5)
    end

    test "returns an error if max number of players have already joined", context do
      {:ok, full_engine} = TestData.join_all(context)

      assert {:error, :room_full} = Engine.join(full_engine, insert_user(), 200)
    end

    test "returns an error if the player has already joined", context do
      {:ok, engine} = Engine.join(Engine.new(), context.p1, 200)

      assert {:error, :already_joined} = Engine.join(engine, context.p1, 200)
    end
  end

  describe "call/2" do
    test "returns an error when the engine is a non-bettable phase", %{p1: p1} do
      {:ok, engine} = Engine.join(Engine.new(), p1, 200)
      engine_2 = %Engine{engine | phase: :game_over}
      engine_3 = %Engine{engine | phase: :between_rounds}

      assert {:error, :non_betting_round} = Engine.call(engine, p1)
      assert {:error, :non_betting_round} = Engine.call(engine_2, p1)
      assert {:error, :non_betting_round} = Engine.call(engine_3, p1)
    end

    test "only allows the active player to call", context do
      {:ok, full_engine} = TestData.join_all(context)
    end
  end
end
