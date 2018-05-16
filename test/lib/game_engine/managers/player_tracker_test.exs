defmodule PokerEx.PlayerTrackerTest do
  use ExUnit.Case, async: true
  use PokerEx.EngineCase
  alias PokerEx.GameEngine.Impl, as: Engine
  alias PokerEx.GameEngine.{PlayerTracker}

  @json "{\"active\":[\"Zack\",\"Raphael\",\"Splinter\",\"April\"],\"all_in\":[\"Zack\",\"Raphael\",\"Splinter\",\"April\"],\"called\":[\"Zack\",\"Raphael\",\"Splinter\",\"April\"],\"folded\":[\"Zack\",\"Raphael\",\"Splinter\",\"April\"]}"
  @struct %PokerEx.GameEngine.PlayerTracker{
    active: ["Zack", "Raphael", "Splinter", "April"],
    all_in: ["Zack", "Raphael", "Splinter", "April"],
    called: ["Zack", "Raphael", "Splinter", "April"],
    folded: ["Zack", "Raphael", "Splinter", "April"]
  }

  describe "call/3" do
    test "moves the calling player into the list of called players", context do
      engine =
        Map.put(Engine.new(), :player_tracker, TestData.insert_active_players(context))
        |> Map.put(:chips, TestData.add_200_chips_for_all(context))
        |> Map.update(:chips, %{}, fn chips -> Map.put(chips, :to_call, 10) end)

      [active_player | _] = engine.player_tracker.active

      engine =
        Map.update(engine, :chips, %{}, fn chips ->
          Map.update(chips, :round, %{}, fn round -> Map.put(round, active_player, 10) end)
        end)

      assert {:ok, player_tracker} = PlayerTracker.call(engine, active_player, engine.chips)
      assert active_player in player_tracker.called
      refute hd(player_tracker.active) == active_player
    end

    test "does not move the players who have not called into the called list", context do
      engine =
        Map.put(Engine.new(), :player_tracker, TestData.insert_active_players(context))
        |> Map.put(:chips, TestData.add_200_chips_for_all(context))
        |> Map.update(:chips, %{}, fn chips -> Map.put(chips, :to_call, 10) end)

      [active_player | _] = engine.player_tracker.active

      assert {:error, :player_did_not_call} =
               PlayerTracker.call(engine, active_player, engine.chips)
    end

    test "moves a player to all_in if the player runs out of chips", context do
      engine =
        Map.put(Engine.new(), :player_tracker, TestData.insert_active_players(context))
        |> Map.put(:chips, TestData.add_200_chips_for_all(context))
        |> Map.update(:chips, %{}, fn chips -> Map.put(chips, :to_call, 250) end)

      [active_player | _] = engine.player_tracker.active

      engine =
        Map.update(engine, :chips, %{}, fn chips ->
          Map.update(chips, :round, %{}, fn round -> Map.put(round, active_player, 200) end)
          |> Map.update(:chip_roll, %{}, fn chip_roll -> Map.put(chip_roll, active_player, 0) end)
        end)

      assert {:ok, player_tracker} = PlayerTracker.call(engine, active_player, engine.chips)
      assert active_player in player_tracker.all_in
    end
  end

  describe "raise/3" do
    test "clears the called list and inserts the raising player", context do
      engine =
        Map.put(Engine.new(), :player_tracker, TestData.insert_active_players(context))
        |> Map.put(:chips, TestData.add_200_chips_for_all(context))
        |> Map.update(:chips, %{}, fn chips ->
          Map.update(chips, :round, %{}, fn round ->
            Map.put(round, context.p1.name, 10)
          end)
        end)

      [active_player | _] = engine.player_tracker.active

      assert {:ok, _player_tracker} = PlayerTracker.raise(engine, active_player, engine.chips)
    end

    test "places the raising player at the end of the active player list", context do
      engine =
        Map.put(Engine.new(), :player_tracker, TestData.insert_active_players(context))
        |> Map.put(:chips, TestData.add_200_chips_for_all(context))
        |> Map.update(:chips, %{}, fn chips ->
          Map.update(chips, :round, %{}, fn round ->
            Map.put(round, context.p1.name, 10)
          end)
        end)

      [active_player | _] = engine.player_tracker.active

      assert {:ok, player_tracker} = PlayerTracker.raise(engine, active_player, engine.chips)
      assert active_player == List.last(player_tracker.active)
    end

    test "places the raising player in all_in when using all chips", context do
      engine =
        Map.put(Engine.new(), :player_tracker, TestData.insert_active_players(context))
        |> Map.put(:chips, TestData.add_200_chips_for_all(context))

      [active_player | _] = engine.player_tracker.active

      engine =
        Map.update(engine, :chips, %{}, fn chips ->
          Map.update(chips, :chip_roll, %{}, fn chip_roll ->
            Map.put(chip_roll, active_player, 0)
          end)
          |> Map.update(:round, %{}, fn round ->
            Map.put(round, active_player, 10)
          end)
        end)

      assert {:ok, player_tracker} = PlayerTracker.raise(engine, active_player, engine.chips)
      assert active_player in player_tracker.all_in
      refute active_player in player_tracker.active
    end
  end

  describe "fold/2" do
    test "moves the folding player from active to folded", context do
      engine = Map.put(Engine.new(), :player_tracker, TestData.insert_active_players(context))

      [active_player | _] = engine.player_tracker.active

      {:ok, player_tracker} = PlayerTracker.fold(engine, active_player)
      assert active_player in player_tracker.folded
      refute active_player in player_tracker.active
    end

    test "requires the player to be active", context do
      engine = Map.put(Engine.new(), :player_tracker, TestData.insert_active_players(context))

      non_active_player = Enum.drop(engine.player_tracker.active, 1) |> hd()

      assert {:error, :player_not_active} = PlayerTracker.fold(engine, non_active_player)
    end
  end

  describe "check/2" do
    test "places the checking player in the called list if player can check", context do
      engine = Map.put(Engine.new(), :player_tracker, TestData.insert_active_players(context))
      [active_player | _] = engine.player_tracker.active

      engine =
        Map.update(engine, :chips, %{}, fn chips ->
          Map.update(chips, :round, %{}, fn round -> Map.put(round, active_player, 10) end)
        end)
        |> Map.update(:chips, %{}, fn chips -> Map.put(chips, :to_call, 10) end)

      assert {:ok, player_tracker} = PlayerTracker.check(engine, active_player)

      assert active_player in player_tracker.called
    end
  end

  describe "reset_round/1" do
    test "clears the called list", context do
      engine =
        Map.put(Engine.new(), :player_tracker, TestData.insert_active_players(context))
        |> Map.update(:player_tracker, %{}, fn tracker ->
          Map.put(tracker, :called, [context.p1.name, context.p2.name])
        end)

      assert tracker = PlayerTracker.reset_round(engine.player_tracker)
      assert [] == tracker.called
    end
  end

  describe "is_player_active?/2" do
    test "returns true if the player is at the front of the active list", context do
      engine = Map.put(Engine.new(), :player_tracker, TestData.insert_active_players(context))

      assert PlayerTracker.is_player_active?(engine, context.p1.name)
    end

    test "returns false if the player is not at the front of the active list", context do
      engine = Map.put(Engine.new(), :player_tracker, TestData.insert_active_players(context))

      refute PlayerTracker.is_player_active?(engine, context.p2.name)
    end
  end

  describe "serialization" do
    test "serializes PlayerTracker structs into JSON values", _ do
      assert {:ok, actual} = Jason.encode(@struct)
      assert actual == @json
    end

    test "deserializes JSON values into PlayerTracker structs", _ do
      assert {:ok, actual} = PlayerTracker.decode(@json)
      assert actual == @struct
    end
  end
end
