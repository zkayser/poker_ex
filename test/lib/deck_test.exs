defmodule PokerEx.DeckTest do
	use ExUnit.Case
	alias PokerEx.Deck
	alias PokerEx.Card
	
	
	test "new_deck creates a deck containing all cards" do
		# Random sample
		cards = [%Card{suit: :hearts, rank: :queen}, %Card{suit: :spades, rank: :ace}, %Card{suit: :diamonds, rank: :two}]
		deck = Deck.new
		assert Enum.all?(cards, &(&1 in deck.cards)), "Not all cards were included"
	end
end