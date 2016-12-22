defmodule PokerEx.Hand do
	alias PokerEx.Hand
	alias PokerEx.Card
	
	@type t :: %Hand{hand: [Card.t], type_string: String.t, hand_type: atom, score: pos_integer, has_flush_with: [Card.t] | nil, 
									 has_straight_with: [Card.t] | nil, has_n_kind_with: [Card.t] | nil, best_hand: [Card.t] | nil}
	
	defstruct hand: nil, type_string: nil, hand_type: nil, score: nil, has_flush_with: nil, has_straight_with: nil, has_n_kind_with: nil,
			  		best_hand: nil
end