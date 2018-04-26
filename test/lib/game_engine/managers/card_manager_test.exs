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
      engine = Map.put(Engine.new(), :seating, TestData.seat_players(context))

      engine =
        Map.update(engine, :cards, %{}, fn card_manager ->
          {:ok, card_manager} = CardManager.deal(engine, :pre_flop)
          card_manager
        end)

      assert {:ok, card_manager} = CardManager.deal(engine, :flop)

      for card <- card_manager.table do
        deck = card_manager.deck
        refute card in deck.cards
      end

      assert length(card_manager.table) == 3
    end
  end
end
