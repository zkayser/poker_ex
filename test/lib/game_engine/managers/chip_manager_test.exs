defmodule PokerEx.ChipManagerTest do
  use ExUnit.Case, async: true
  use PokerEx.EngineCase
  alias PokerEx.GameEngine.Impl, as: Engine
  alias PokerEx.GameEngine.{ChipManager, RoleManager, Seating}

  @json_card_manager "{\"chip_roll\":{\"Jane\":300,\"Zack\":400},\"in_play\":{},\"paid\":{\"Jane\":40,\"Zack\":30},\"pot\":70,\"round\":{\"Jane\":5,\"Zack\":10},\"to_call\":10}"
  @card_manager_struct %PokerEx.GameEngine.ChipManager{
    chip_roll: %{"Jane" => 300, "Zack" => 400},
    in_play: %{},
    paid: %{"Jane" => 40, "Zack" => 30},
    pot: 70,
    round: %{"Jane" => 5, "Zack" => 10},
    to_call: 10
  }

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
      {%{name: big_blind}, %{name: small_blind}} = {insert_user(), insert_user()}

      engine = Engine.new()
      seating = %Seating{arrangement: [{big_blind, 0}, {small_blind, 1}]}
      chips = %{engine.chips | chip_roll: %{big_blind => 200, small_blind => 200}}

      engine = %Engine{
        engine
        | seating: seating,
          chips: chips
      }

      engine = Map.put(engine, :roles, RoleManager.manage_roles(engine))

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

    test "does not allow raises above the amount the player controls", context do
      engine =
        Map.put(Engine.new(), :player_tracker, TestData.insert_active_players(context))
        |> Map.put(:chips, TestData.add_200_chips_for_all(context))
        |> Map.update(:chips, %{}, fn chips -> Map.put(chips, :to_call, 10) end)
        |> Map.update(:chips, %{}, fn chips -> Map.put(chips, :pot, 10) end)

      [active_player | _] = engine.player_tracker.active
      assert {:ok, chips} = ChipManager.raise(engine, active_player, 300)
      assert chips.to_call == 200
      assert chips.round[active_player] == 200
      assert chips.paid[active_player] == 200
      assert chips.chip_roll[active_player] == 0
      assert chips.pot == 210
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

  describe "check/2" do
    test "allows a check if the player is active and has paid the to_call amount", context do
      engine =
        Map.put(Engine.new(), :player_tracker, TestData.insert_active_players(context))
        |> Map.update(:chips, %{}, fn chips -> Map.put(chips, :to_call, 10) end)

      [active_player | _] = engine.player_tracker.active

      engine =
        Map.update(engine, :chips, %{}, fn chips ->
          Map.update(chips, :round, %{}, fn round -> Map.put(round, active_player, 10) end)
        end)

      assert {:ok, chips} = ChipManager.check(engine, active_player)
      assert chips == engine.chips
    end

    test "errors if the player has not paid the to_call amount", context do
      engine =
        Map.put(Engine.new(), :player_tracker, TestData.insert_active_players(context))
        |> Map.update(:chips, %{}, fn chips -> Map.put(chips, :to_call, 10) end)

      [active_player | _] = engine.player_tracker.active

      assert {:error, :not_paid} = ChipManager.check(engine, active_player)
    end

    test "errors if the player tries to go out of turn", context do
      engine = Map.put(Engine.new(), :player_tracker, TestData.insert_active_players(context))

      non_active_player = Enum.drop(engine.player_tracker.active, 1) |> hd()

      assert {:error, :out_of_turn} = ChipManager.check(engine, non_active_player)
    end
  end

  describe "leave/2" do
    test "removes the player from the chip_roll", context do
      engine =
        Map.put(Engine.new(), :player_tracker, TestData.insert_active_players(context))
        |> Map.put(:chips, TestData.add_200_chips_for_all(context))

      assert {:ok, chips} = ChipManager.leave(engine, context.p1.name)
      refute Map.has_key?(chips.chip_roll, context.p1.name)
    end
  end

  describe "reset_round/1" do
    test "resets the round map to a blank and to_call to 0", context do
      engine =
        Map.put(Engine.new(), :player_tracker, TestData.insert_active_players(context))
        |> Map.update(:chips, %{}, fn chips ->
          Map.put(chips, :round, %{context.p1.name => 200, context.p2.name => 100})
        end)

      # The above round map inserted on line 220 is completely arbitrary. It should
      # be wiped out when the round is reset.

      assert chips = ChipManager.reset_round(engine.chips)
      assert chips.round == %{}
      refute context.p1.name in Map.keys(chips.round)
      refute context.p2.name in Map.keys(chips.round)
      assert chips.to_call == 0
    end
  end

  describe "reset_game/1" do
    test "resets everything except for the chip roll", context do
      engine =
        Map.put(Engine.new(), :player_tracker, TestData.insert_active_players(context))
        |> Map.put(:chips, TestData.add_200_chips_for_all(context))
        |> Map.update(:chips, %{}, fn chips ->
          Map.put(chips, :round, %{context.p1.name => 20, context.p2.name => 40})
        end)
        |> Map.update(:chips, %{}, fn chips ->
          Map.put(chips, :paid, %{context.p1.name => 100, context.p2.name => 100})
        end)

      assert chips = ChipManager.reset_game(engine.chips)
      assert map_size(chips.round) == 0
      assert map_size(chips.paid) == 0
      assert chips.to_call == 0
      assert chips.pot == 0
      assert chips.chip_roll == engine.chips.chip_roll
    end

    test "removes players with 0 chips in the chip roll", context do
      engine =
        Map.put(Engine.new(), :player_tracker, TestData.insert_active_players(context))
        |> Map.put(:chips, TestData.add_200_chips_for_all(context))
        |> Map.update(:chips, %{}, fn chips ->
          Map.update(chips, :chip_roll, %{}, fn chip_roll ->
            Map.put(chip_roll, context.p3.name, 0)
          end)
        end)

      # Above, we insert 200 chips into the chip roll for all players, then
      # arbitrarily set player 3's chip roll to 0. Player 3 should be removed
      # on game reset.
      chips = ChipManager.reset_game(engine.chips)
      refute context.p3.name in Map.keys(chips.chip_roll)
    end
  end

  describe "can_player_check?/2" do
    test "returns true if the player has paid the to_call amount", context do
      engine =
        Map.put(Engine.new(), :player_tracker, TestData.insert_active_players(context))
        |> Map.update(:chips, %{}, fn chips ->
          %{chips | to_call: 10, round: Map.put(%{}, context.p1.name, 10)}
        end)

      assert ChipManager.can_player_check?(engine, context.p1.name)
    end

    test "returns true if the to_call amount is 0", context do
      engine = Map.put(Engine.new(), :player_tracker, TestData.insert_active_players(context))

      assert ChipManager.can_player_check?(engine, context.p1.name)
    end

    test "returns false if the player is not active", context do
      engine = Map.put(Engine.new(), :player_tracker, TestData.insert_active_players(context))

      refute ChipManager.can_player_check?(engine, context.p2.name)
    end
  end

  describe "serialization" do
    test "can decode a ChipManager struct from JSON" do
      assert {:ok, actual} = ChipManager.decode(@json_card_manager)
      assert actual == @card_manager_struct
    end

    test "can encode JSON from a ChipManager struct" do
      assert {:ok, actual} = Jason.encode(@card_manager_struct)
      assert actual == @json_card_manager
    end
  end
end
