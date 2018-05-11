defmodule PokerEx.HandTest do
  use ExUnit.Case
  alias PokerEx.Hand

  @json "{\"best_hand\":[{\"rank\":\"two\",\"suit\":\"hearts\"},{\"rank\":\"three\",\"suit\":\"diamonds\"}],\"hand\":[{\"rank\":\"four\",\"suit\":\"spades\"},{\"rank\":\"five\",\"suit\":\"diamonds\"}],\"hand_type\":\"flush\",\"has_flush_with\":[{\"rank\":\"six\",\"suit\":\"hearts\"},{\"rank\":\"seven\",\"suit\":\"clubs\"}],\"has_n_kind_with\":null,\"has_straight_with\":null,\"score\":400,\"type_string\":\"A flush, seven high\"}"
  @struct %Hand{
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

  describe "serialization" do
    test "serializes from Hand struct into JSON values" do
      assert {:ok, actual} = Jason.encode(@struct)
      assert actual == @json
    end

    test "deserializes from JSON values into Hand structs" do
      assert {:ok, actual} = Hand.decode(@json)
      assert actual == @struct
    end
  end
end
