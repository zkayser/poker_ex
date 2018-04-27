defmodule PokerEx.CardManagerTest do
  use ExUnit.Case
  use PokerEx.EngineCase
  alias PokerEx.GameEngine.Impl, as: Engine
  alias PokerEx.GameEngine.{CardManager}

  describe "deal/2" do
    test "deals player cards when phase changes to pre_flop", context do
      engine = Map.put(Engine.new(), :seating, TestData.seat_players(context))

      # Assert player_hands length == 6 because six active players
      # are inserted above and all should have cards. Then 2 cards
      # for each player.

      assert {:ok, card_manager} = CardManager.deal(engine, :pre_flop)
      assert length(card_manager.player_hands) == 6
      assert hd(card_manager.player_hands).player == elem(hd(engine.seating.arrangement), 0)
      assert length(hd(card_manager.player_hands).hand) == 2
      assert [] = card_manager.table
    end

    test "deals three cards on the table when transitioning to the flop", context do
      engine = TestData.setup_cards_and_deck(context)
      assert {:ok, card_manager} = CardManager.deal(engine, :flop)

      for card <- card_manager.table do
        deck = card_manager.deck
        refute card in deck.cards
      end

      assert length(card_manager.table) == 3
    end

    test "deals one card on the table when transitioning to the turn", context do
      engine = TestData.setup_cards_and_deck(context)
      {:ok, card_manager} = CardManager.deal(engine, :flop)
      engine = %Engine{engine | cards: card_manager}

      assert {:ok, card_manager} = CardManager.deal(engine, :turn)
      assert length(card_manager.table) == 4
    end

    test "deals one card on the table when transitioning to the river", context do
      engine = TestData.setup_cards_and_deck(context)
      {:ok, card_manager} = CardManager.deal(engine, :flop)
      engine = %Engine{engine | cards: card_manager}
      {:ok, card_manager} = CardManager.deal(engine, :turn)
      engine = %Engine{engine | cards: card_manager}

      assert {:ok, card_manager} = CardManager.deal(engine, :river)
      assert length(card_manager.table) == 5
    end

    test "clears the deck when transitioning between rounds", context do
      engine = TestData.setup_cards_and_deck(context)

      assert {:ok, card_manager} = CardManager.deal(engine, :between_rounds)
      assert [] = card_manager.table
      assert [] = card_manager.deck
      assert [] = card_manager.player_hands
    end
  end

  describe "fold/2" do
    test "removes the folding player's cards from the card manager", context do
      engine = TestData.setup_cards_and_deck(context)

      assert {:ok, card_manager} = CardManager.fold(engine, context.p1.name)
      remaining_hands = Enum.map(card_manager.player_hands, fn data -> data.player end)
      refute context.p1 in remaining_hands
    end
  end
end
