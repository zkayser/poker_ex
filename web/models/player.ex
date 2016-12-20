defmodule PokerEx.Player do
	# Opting out of the PokerEx.Web, :model for the time being
	# Will add it in if it becomes necessary.
	alias PokerEx.Player
	alias PokerEx.Card
	alias PokerEx.AppState
	
	@type t :: %Player{name: String.t, chips: non_neg_integer, hand: [Card.t] | nil}
	
	defstruct name: nil, chips: nil, hand: nil, position: nil
	
	@spec bet(String.t, non_neg_integer) :: Player.t
	def bet(name, amount) do
		player = case AppState.get(name) do
			%Player{name: name, chips: chips} -> %Player{name: name, chips: chips}
			_ -> :player_not_found
		end
		
		case player.chips >= amount do
			true -> %Player{player | chips: player.chips - amount} |> update
			_ -> :insufficient_chips
		end
	end
	
	@spec reward(String.t, non_neg_integer) :: Player.t
	def reward(name, amount) do
		player = case AppState.get(name) do
			%Player{name: name, chips: chips} -> %Player{name: name, chips: chips}
			_ -> :player_not_found
		end
	
		%Player{ player | chips: player.chips + amount} |> update
	end
	
	def update(player) do
		AppState.get_and_update(player)
	end
end