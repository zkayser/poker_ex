defmodule PokerEx.SeatingTest do
  use ExUnit.Case, async: false
  use PokerEx.EngineCase
  alias PokerEx.GameEngine.Impl, as: Engine
  alias PokerEx.GameEngine.{Seating}
  @json "[{\"Zack\":0},{\"Sally\":1},{\"Fred\":2}]"
  @struct %Seating{arrangement: [{"Zack", 0}, {"Sally", 1}, {"Fred", 2}]}

  describe "join/2" do
    test "returns an error if the room is already full", context do
      engine = Map.put(Engine.new(), :seating, TestData.seat_players(context))

      assert {:error, :room_full} = Seating.join(engine, %PokerEx.Player{name: "Donatello"})
    end

    test "returns an error if the player has already joined", context do
      engine =
        Map.update(Engine.new(), :seating, %{}, fn seating ->
          Map.put(seating, :arrangement, [{context.p1, 0}])
        end)

      assert {:error, :already_joined} = Seating.join(engine, context.p1)
    end

    test "positions second player in seat index 1", context do
      engine =
        Map.update(Engine.new(), :seating, %{}, fn seating ->
          Map.put(seating, :arrangement, [{context.p1, 0}])
        end)

      assert {:ok, seating} = Seating.join(engine, context.p2)
      assert [{context.p1, 0}, {context.p2, 1}] == seating.arrangement
    end

    test "handles reindexing when some players leave", context do
      engine =
        Map.update(Engine.new(), :seating, %{}, fn seating ->
          Map.put(seating, :arrangement, [{context.p1, 1}, {context.p2, 2}])
        end)

      assert {:ok, seating} = Seating.join(engine, context.p3)
      assert {context.p3, 0} == hd(seating.arrangement)
    end

    test "handles reindexing with gaps", context do
      engine =
        Map.update(Engine.new(), :seating, %{}, fn seating ->
          Map.put(seating, :arrangement, [
            {context.p1, 3},
            {context.p2, 4},
            {context.p3, 0},
            {context.p4, 1},
            {context.p5, 2}
          ])
        end)

      assert {:ok, seating} = Seating.join(engine, context.p6)
      assert {context.p6, 5} == Enum.at(seating.arrangement, 2)
    end

    test "handles reindexing with gap at index 0", context do
      engine =
        Map.update(Engine.new(), :seating, %{}, fn seating ->
          Map.put(seating, :arrangement, [
            {context.p1, 3},
            {context.p2, 4},
            {context.p3, 1},
            {context.p4, 2}
          ])
        end)

      assert {:ok, seating} = Seating.join(engine, context.p5)
      assert {context.p5, 0} == Enum.at(seating.arrangement, 2)
    end

    test "handles reindexing with multiple gaps", context do
      engine =
        Map.update(Engine.new(), :seating, %{}, fn seating ->
          Map.put(seating, :arrangement, [
            {context.p1, 2},
            {context.p2, 4},
            {context.p3, 5}
          ])
        end)

      assert {:ok, seating} = Seating.join(engine, context.p4)
      assert {context.p4, 0} == hd(seating.arrangement)
    end
  end

  describe "leave/2" do
    test "removes the player from the seating arrangement", context do
      engine = Map.put(Engine.new(), :seating, TestData.seat_players(context))

      new_seating = Seating.leave(engine, context.p2)

      refute context.p2 in Enum.map(new_seating.arrangement, fn {player, _} ->
               player
             end)
    end
  end

  describe "cycle/1" do
    test "moves the player in front of the seating arrangement to the back", context do
      engine = Map.put(Engine.new(), :seating, TestData.seat_players(context))

      [hd | _] = engine.seating.arrangement
      new_seating = Seating.cycle(engine)
      [new_head | _tail] = new_seating.arrangement

      refute hd == new_head
      assert hd == List.last(new_seating.arrangement)
    end
  end

  describe "is_player_seated?/2" do
    test "returns true if the player is in the seating arrangement", context do
      engine = Map.put(Engine.new(), :seating, TestData.seat_players(context))

      assert Seating.is_player_seated?(engine, context.p1)
    end

    test "returns false if the player is not in the seating arrangment", context do
      refute Seating.is_player_seated?(Engine.new(), context.p1)
    end
  end

  describe "serialization" do
    test "serializes Seating structs into JSON values" do
      assert {:ok, actual} = Jason.encode(@struct)
      assert actual == @json
    end

    test "deserializes JSON seating values into Seating structs" do
      assert {:ok, actual} = Seating.decode(@json)
      assert actual == @struct
    end
  end
end
