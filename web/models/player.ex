defmodule PokerEx.Player do
	# Opting out of the PokerEx.Web, :model for the time being.
	# Will add it in if it becomes necessary.
	alias PokerEx.Player
	alias PokerEx.AppState
	alias PokerEx.Events
	
	@type t :: %Player{name: String.t, chips: non_neg_integer}
	
	defstruct name: nil, chips: nil
	
	@spec new(String.t, pos_integer) :: Player.t
	def new(name, chips \\ 1000) do
		%Player{name: name, chips: chips}
	end
	
	@spec bet(String.t, non_neg_integer, atom()) :: Player.t | {:insufficient_chips, non_neg_integer}
	def bet(name, amount, room_id \\ nil) do
		player = case AppState.get(name) do
			%Player{name: name, chips: chips} -> %Player{name: name, chips: chips}
			_ -> :player_not_found
		end
		
		case player.chips > amount do
			true -> 
				Events.chip_update(room_id, player, player.chips - amount)
				Events.pot_update(room_id, amount)
				%Player{player | chips: player.chips - amount} |> update
			_ -> 
				total = player.chips
				Events.chip_update(room_id, player, 0)
				Events.pot_update(room_id, total)
				%Player{player | chips: 0} |> update
				{:insufficient_chips, total}
		end
	end
	
	@spec reward(String.t, non_neg_integer, atom()) :: Player.t
	def reward(name, amount, room_id) do
		player = case AppState.get(name) do
			%Player{name: name, chips: chips} -> %Player{name: name, chips: chips}
			_ -> :player_not_found
		end
		
		Events.chip_update(room_id, player, player.chips + amount)
		%Player{ player | chips: player.chips + amount} |> update
	end
	
	def update(player) do
		AppState.get_and_update(player)
	end
end