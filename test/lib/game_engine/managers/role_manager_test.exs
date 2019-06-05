defmodule PokerEx.RoleManagerTest do
  use ExUnit.Case, async: false
  use PokerEx.EngineCase
  alias PokerEx.GameEngine.Impl, as: Engine
  alias PokerEx.GameEngine.{RoleManager, Seating}
  @unset_json "{\"big_blind\":\"unset\",\"dealer\":\"unset\",\"small_blind\":\"unset\"}"
  @unset_struct %PokerEx.GameEngine.RoleManager{
    big_blind: :unset,
    dealer: :unset,
    small_blind: :unset
  }
  @set_json "{\"big_blind\":2,\"dealer\":0,\"small_blind\":1}"
  @set_struct %PokerEx.GameEngine.RoleManager{dealer: 0, small_blind: 1, big_blind: 2}

  describe "manage_roles/1" do
    test "sets big blind and dealer to 0, small blind to 1 when all are unset and two or more players join",
         context do
      engine = Map.put(Engine.new(), :seating, TestData.seat_players(context))
      assert roles = RoleManager.manage_roles(engine)
      assert roles.dealer == 0
      assert roles.big_blind == 2
      assert roles.small_blind == 1
    end

    test "alternates big_blind/dealer with small_blind when there are only two players",
         context do
      engine = Map.put(Engine.new(), :seating, TestData.seat_two(context))
      assert roles = RoleManager.manage_roles(engine)
      assert roles.dealer == 0
      assert roles.big_blind == 0
      assert roles.small_blind == 1

      engine = Map.put(engine, :seating, Seating.cycle(engine))
      assert roles = RoleManager.manage_roles(engine)

      assert roles.dealer == 1
      assert roles.big_blind == 1
      assert roles.small_blind == 0
    end

    test "resets dealer to 0 when it has reached the final seated player", context do
      engine =
        Map.put(Engine.new(), :seating, TestData.seat_players(context))
        |> Map.put(:roles, %RoleManager{dealer: 5, big_blind: 0, small_blind: 1})

      engine =
        Enum.reduce(0..5, engine, fn _, acc ->
          Map.update(acc, :seating, %{}, fn _seating -> Seating.cycle(acc) end)
        end)

      assert roles = RoleManager.manage_roles(engine)
      assert roles.dealer == 0
      assert roles.big_blind == 2
      assert roles.small_blind == 1
    end

    test "resets big_blind to 0 when it has reached the final seated player", context do
      engine =
        Map.put(Engine.new(), :seating, TestData.seat_players(context))
        |> Map.put(:roles, %RoleManager{dealer: 3, big_blind: 5, small_blind: 4})

      engine =
        Enum.reduce(0..3, engine, fn _, acc ->
          Map.update(acc, :seating, %{}, fn _seating -> Seating.cycle(acc) end)
        end)

      assert roles = RoleManager.manage_roles(engine)
      assert roles.dealer == 4
      assert roles.big_blind == 0
      assert roles.small_blind == 5
    end

    test "resets the small_blind to 0 when it has reached the final seated player", context do
      engine =
        Map.put(Engine.new(), :seating, TestData.seat_players(context))
        |> Map.put(:roles, %RoleManager{dealer: 4, small_blind: 5, big_blind: 0})

      engine =
        Enum.reduce(0..4, engine, fn _, acc ->
          Map.update(acc, :seating, %{}, fn _seating -> Seating.cycle(acc) end)
        end)

      assert roles = RoleManager.manage_roles(engine)
      assert roles.dealer == 5
      assert roles.small_blind == 0
      assert roles.big_blind == 1
    end
  end

  describe "serialization" do
    test "serializes unset RoleManager structs into JSON values", _ do
      assert {:ok, actual} = Jason.encode(@unset_struct)
      assert actual == @unset_json
    end

    test "serializes set RoleManager structs into JSON values", _ do
      assert {:ok, actual} = Jason.encode(@set_struct)
      assert actual == @set_json
    end

    test "deserializes unset role manager JSON into RoleManager structs", _ do
      assert {:ok, actual} = RoleManager.decode(@unset_json)
      assert actual == @unset_struct
    end

    test "deserializes set role manager JSON into RoleManager structs", _ do
      assert {:ok, actual} = RoleManager.decode(@set_json)
      assert actual == @set_struct
    end
  end
end
