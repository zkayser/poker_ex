defmodule PokerEx.TableState do
	alias PokerEx.TableState, as: State

	@type t :: %State{}

	defstruct seating: [], active: [], big_blind: nil, small_blind: nil, length: nil, current_big_blind: nil,
						current_small_blind: nil, bet_history: %{}, current_player: nil, next_player: nil, dealer: nil
end