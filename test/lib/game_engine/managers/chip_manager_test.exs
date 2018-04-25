defmodule PokerEx.ChipManagerTest do
  use ExUnit.Case
  use PokerEx.EngineCase
  alias PokerEx.GameEngine.Impl, as: Engine
  alias PokerEx.GameEngine.{ChipManager}

  describe "join/3" do
    test "enforces players to join with at least 100 chips", _ do
      assert {:error, :join_amount_insufficient} =
               ChipManager.join(Engine.new(), insert_user(), 95)

      assert {:error, :join_amount_insufficient} =
               ChipManager.join(Engine.new(), insert_user(), 0)

      assert {:error, :join_amount_insufficient} =
               ChipManager.join(Engine.new(), insert_user(), -5)
    end

    test "returns an error if a player tries to join with chips greater than their total", _ do
      assert {:error, :insufficient_chips} = ChipManager.join(Engine.new(), insert_user(), 10_000)
    end

    test "populates the chip_roll map with the player's name and the amount of chips they joined with",
         _ do
      player = insert_user()
      assert {:ok, chips} = ChipManager.join(Engine.new(), player, 200)
      assert chips.chip_roll[player.name] == 200
    end
  end

  describe "post_blinds/1" do
    test "automatically places bets for the small and big blinds", _ do
      {big_blind, small_blind} = {insert_user(), insert_user()}

      engine = Engine.new()
      seating = engine.seating
      chips = engine.chips

      seating = %{
        seating
        | current_big_blind: {big_blind, 0},
          current_small_blind: {small_blind, 1}
      }

      chips = %{chips | chip_roll: %{big_blind => 200, small_blind => 200}}
      engine = %Engine{engine | seating: seating, chips: chips}

      assert {:ok, %{chip_roll: chip_roll, paid: paid, round: round, to_call: 10, pot: 15}} =
               ChipManager.post_blinds(engine)

      # 190 for big_blind because big blind = 10; small blind = 5 -> (200 - 10 & 200 - 5)
      assert %{^big_blind => 190, ^small_blind => 195} = chip_roll
      assert %{^big_blind => 10, ^small_blind => 5} = paid
      assert %{^big_blind => 10, ^small_blind => 5} = round
    end
  end

  describe "call/2" do
    test "manages the amount the active player needs to pay to call", context do
      engine =
        Map.put(Engine.new(), :player_tracker, TestData.insert_active_players(context))
        |> Map.put(:chips, TestData.add_200_chips_for_all(context))
        |> Map.update(:chips, %{}, fn chips -> Map.put(chips, :to_call, 10) end)

      [active_player | _] = engine.player_tracker.active
      assert {:ok, chips} = ChipManager.call(engine, active_player)
      assert chips.chip_roll[active_player] == 190
      assert chips.paid[active_player] == 10
      assert chips.round[active_player] == 10
    end

    test "does not allow non-active players to call", context do
      engine = Map.put(Engine.new(), :player_tracker, TestData.insert_active_players(context))
      non_active_player = engine.player_tracker.active |> Enum.drop(1) |> Enum.take(1)
      assert {:error, :out_of_turn} = ChipManager.call(engine, non_active_player)
    end

    test "allows calls by players with fewer than `to_call` amount of chips", context do
      engine =
        Map.put(Engine.new(), :player_tracker, TestData.insert_active_players(context))
        |> Map.put(:chips, TestData.add_200_chips_for_all(context))

      chips = %{engine.chips | to_call: 400}
      engine = %Engine{engine | chips: chips}
      [active_player | _] = engine.player_tracker.active
      assert {:ok, chips} = ChipManager.call(engine, active_player)
      assert chips.chip_roll[active_player] == 0
      assert chips.paid[active_player] == 200
      assert chips.round[active_player] == 200
    end
  end

  describe "raise/3" do
    test "increases the pot size and removes chips from the player's chip roll", context do
      engine =
        Map.put(Engine.new(), :player_tracker, TestData.insert_active_players(context))
        |> Map.put(:chips, TestData.add_200_chips_for_all(context))
        |> Map.update(:chips, %{}, fn chips -> Map.put(chips, :to_call, 10) end)
        |> Map.update(:chips, %{}, fn chips -> Map.put(chips, :pot, 10) end)

      [active_player | _] = engine.player_tracker.active
      assert {:ok, chips} = ChipManager.raise(engine, active_player, 30)
      assert chips.to_call == 30
      assert chips.pot == 40
      assert chips.chip_roll[active_player] == 170
      assert chips.round[active_player] == 30
      assert chips.paid[active_player] == 30
    end

    test "limits raises to the number of chips the player has in their chip roll", context do
      engine =
        Map.put(Engine.new(), :player_tracker, TestData.insert_active_players(context))
        |> Map.put(:chips, TestData.add_200_chips_for_all(context))

      [active_player | _] = engine.player_tracker.active
      assert {:ok, chips} = ChipManager.raise(engine, active_player, 201)
      assert chips.to_call == 200
      assert chips.round[active_player] == 200
      assert chips.chip_roll[active_player] == 0
    end

    test "does not allow raises if a player does not have enough chips to raise", context do
      engine =
        Map.put(Engine.new(), :player_tracker, TestData.insert_active_players(context))
        |> Map.put(:chips, TestData.add_200_chips_for_all(context))
        |> Map.update(:chips, %{}, fn chips -> Map.put(chips, :to_call, 400) end)
        |> Map.update(:chips, %{}, fn chips -> Map.put(chips, :pot, 400) end)

      [active_player | _] = engine.player_tracker.active
      assert {:ok, chips} = ChipManager.raise(engine, active_player, 200)
      assert chips.to_call == 400
      assert chips.round[active_player] == 200
      assert chips.paid[active_player] == 200
      assert chips.chip_roll[active_player] == 0
      assert chips.pot == 600
    end

    test "manages raises for players who have already paid in round", context do
      engine =
        Map.put(Engine.new(), :player_tracker, TestData.insert_active_players(context))
        |> Map.put(:chips, TestData.add_200_chips_for_all(context))
        |> Map.update(:chips, %{}, fn chips -> Map.put(chips, :to_call, 10) end)
        |> Map.update(:chips, %{}, fn chips -> Map.put(chips, :pot, 10) end)

      [active_player | _] = engine.player_tracker.active

      engine =
        Map.update(engine, :chips, %{}, fn chips ->
          Map.update(chips, :round, %{}, fn round -> Map.put(round, active_player, 10) end)
        end)

      assert {:ok, chips} = ChipManager.raise(engine, active_player, 5)
      assert chips.to_call == 15
      assert chips.round[active_player] == 15
      assert chips.pot == 15
    end

    test "prevents players from going out of turn", context do
      engine =
        Map.put(Engine.new(), :player_tracker, TestData.insert_active_players(context))
        |> Map.put(:chips, TestData.add_200_chips_for_all(context))

      non_active_player = Enum.drop(engine.player_tracker.active, 1) |> hd()

      assert {:error, :out_of_turn} = ChipManager.raise(engine, non_active_player, 20)
    end
  end
end
