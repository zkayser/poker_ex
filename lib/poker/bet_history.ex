defmodule PokerEx.BetHistory do
	
	
	defstruct to_call: nil, current_paid: %{}, paid: [], main_pot: 0,
						side_pots: %{}, paid_in_round: %{}, rewards: nil, round: []
end