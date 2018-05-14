defmodule PokerEx.ScoreManagerTest do
  use ExUnit.Case
  use PokerEx.EngineCase
  alias PokerEx.GameEngine.Impl, as: Engine
  alias PokerEx.GameEngine.{ScoreManager, CardManager}

  @json "{\"game_id\":\"game_id\",\"rewards\":[{\"Zack\":200},{\"Sally\":400}],\"stats\":[{\"Zack\":300},{\"Sally\":301}],\"winners\":[\"Sally\",\"Zack\"],\"winning_hand\":{\"best_hand\":[{\"rank\":\"two\",\"suit\":\"hearts\"},{\"rank\":\"three\",\"suit\":\"diamonds\"}],\"hand\":[{\"rank\":\"four\",\"suit\":\"spades\"},{\"rank\":\"five\",\"suit\":\"diamonds\"}],\"hand_type\":\"flush\",\"has_flush_with\":[{\"rank\":\"six\",\"suit\":\"hearts\"},{\"rank\":\"seven\",\"suit\":\"clubs\"}],\"has_n_kind_with\":null,\"has_straight_with\":null,\"score\":400,\"type_string\":\"A flush, seven high\"}}"
  @struct %PokerEx.GameEngine.ScoreManager{
    game_id: "game_id",
    rewards: [{"Zack", 200}, {"Sally", 400}],
    stats: [{"Zack", 300}, {"Sally", 301}],
    winners: ["Sally", "Zack"],
    winning_hand: %PokerEx.Hand{
      best_hand: [
        %PokerEx.Card{rank: :two, suit: :hearts},
        %PokerEx.Card{rank: :three, suit: :diamonds}
      ],
      hand: [
        %PokerEx.Card{rank: :four, suit: :spades},
        %PokerEx.Card{rank: :five, suit: :diamonds}
      ],
      hand_type: :flush,
      has_flush_with: [
        %PokerEx.Card{rank: :six, suit: :hearts},
        %PokerEx.Card{rank: :seven, suit: :clubs}
      ],
      has_n_kind_with: nil,
      has_straight_with: nil,
      score: 400,
      type_string: "A flush, seven high"
    }
  }

  describe "manage_score/1" do
    test "is a no-op if the game is not in a game over phase", _ do
      blank_score_manager = ScoreManager.new()
      assert blank_score_manager == ScoreManager.manage_score(Engine.new())
    end

    test "is a no-op if the game if phase is game over but not all cards dealt", context do
      blank_score_manager = ScoreManager.new()

      engine =
        Map.put(Engine.new(), :seating, TestData.seat_players(context))
        |> Map.put(:player_tracker, TestData.insert_active_players(context))

      engine =
        Map.put(
          engine,
          :player_tracker,
          TestData.all_in_for_all_but_first(engine.player_tracker, context)
        )

      engine =
        Map.update(engine, :cards, %{}, fn _ ->
          {:ok, cards} = CardManager.deal(engine, :pre_flop)
          cards
        end)
        |> Map.put(:phase, :game_over)

      assert blank_score_manager == ScoreManager.manage_score(engine)
    end

    test "evaluates each players hand when game is over", context do
      engine = Map.put(Engine.new(), :seating, TestData.seat_players(context))

      engine =
        Map.update(engine, :cards, %{}, fn _ ->
          {:ok, cards} = CardManager.deal(engine, :pre_flop)
          cards
        end)

      engine =
        Map.update(engine, :cards, %{}, fn _ ->
          {:ok, cards} = CardManager.deal(engine, :flop)
          cards
        end)

      engine =
        Map.update(engine, :cards, %{}, fn _ ->
          {:ok, cards} = CardManager.deal(engine, :turn)
          cards
        end)

      engine =
        Map.update(engine, :cards, %{}, fn _ ->
          {:ok, cards} = CardManager.deal(engine, :river)
          cards
        end)
        |> Map.put(:phase, :game_over)
        |> Map.put(:chips, TestData.pay_200_chips_for_all(context))

      scoring = ScoreManager.manage_score(engine)
      {_, high_score} = Enum.max_by(scoring.stats, fn {_, score} -> score end)

      expected_winners =
        Enum.filter(scoring.stats, fn {_, score} -> score == high_score end)
        |> Enum.map(fn {player, _} -> player end)

      assert length(scoring.stats) == 6
      assert is_list(scoring.rewards) && length(scoring.rewards) > 0

      for winner <- expected_winners do
        assert winner in scoring.winners
      end

      assert scoring.winning_hand
    end

    test "selects the only remaining player as the winner when all others fold", context do
      engine =
        Map.put(Engine.new(), :seating, TestData.seat_players(context))
        |> Map.put(:player_tracker, TestData.insert_active_players(context))

      engine =
        Map.put(
          engine,
          :player_tracker,
          TestData.fold_for_all_but_first(engine.player_tracker, context)
        )
        |> Map.put(:chips, TestData.pay_200_chips_for_all(context))
        |> Map.put(:phase, :game_over)

      scoring = ScoreManager.manage_score(engine)
      assert length(scoring.stats) == 1
      assert length(scoring.rewards) == 1
      assert context.p1.name == hd(scoring.winners)
      assert :none = scoring.winning_hand
    end
  end

  describe "serialization" do
    test "serializes ScoreManager structs into JSON values", _ do
      assert {:ok, actual} = Jason.encode(@struct)
      assert actual == @json
    end

    test "deserializes JSON values into ScoreManager structs", _ do
      assert {:ok, actual} = ScoreManager.decode(@json)
      assert actual == @struct
    end
  end
end
