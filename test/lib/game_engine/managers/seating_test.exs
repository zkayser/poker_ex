defmodule PokerEx.SeatingTest do
  use ExUnit.Case
  use PokerEx.EngineCase
  alias PokerEx.GameEngine.Impl, as: Engine
  alias PokerEx.GameEngine.{Seating}

  describe "join/2" do
    test "returns an error if the room is already full", context do
      engine = Map.put(Engine.new(), :seating, TestData.seat_players(context))

      assert {:error, :room_full} = Seating.join(engine, %PokerEx.Player{name: "Donatello"})
    end

    test "returns an error if the player has already joined", context do
      engine =
        Map.update(Engine.new(), :seating, %{}, fn seating ->
          Map.put(seating, :arrangement, [{context.p1.name, 0}])
        end)

      assert {:error, :already_joined} = Seating.join(engine, context.p1)
    end

    test "sets blind positions when a second player joins", context do
      engine =
        Map.update(Engine.new(), :seating, %{}, fn seating ->
          Map.put(seating, :arrangement, [{context.p1.name, 0}])
        end)

      assert {:ok, seating} = Seating.join(engine, context.p2)
      assert seating.current_big_blind == 1
      assert seating.current_small_blind == 0
    end
  end
end
