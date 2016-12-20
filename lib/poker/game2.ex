defmodule PokerEx.Game2 do
	alias PokerEx.BetServer
	alias PokerEx.TableManager
	alias PokerEx.HandServer
	alias PokerEx.Player
	alias PokerEx.AppState
	
	@type t :: %{called: [String.t] | [], player: [String.t] | []}
	
	
	def new do
		%{called: []}
	end
	
	def check(%{called: called} = game, player, paid, to_call) when paid == to_call do
		%{game | called: called ++ [called]}
		TableManager.advance
	end
	
	def call(%{called: called} = game, player) do
		paid = BetServer.get_paid_in_round(player) || 0
		to_call = BetServer.get_to_call
		
		call_amount = to_call - paid
		
		real_amount = 
			case Player.bet(player, call_amount) do
				%Player{name: _, chips: _} -> call_amount
				:insufficient_chips ->
					pl = AppState.get(player)
					Player.bet(player, pl.chips)
					TableManager.all_in(player)
				_ -> raise "Something went wrong in Player.bet"
			end
			
			BetServer.bet(player, real_amount, call_amount)
			TableManager.advance
			
			game = %{game | called: called ++ [player]}
	end
	
	def raise_pot(game, player, amount, to_call) when amount > to_call do
		paid = BetServer.get_paid_in_round(player) || 0
		call_amount = amount - paid
		
		# As a security measure, check that the player has enough chips
		# to make the call. If not, put the player all in and commit
		# a bet to the BetServer for the total remaining chips that
		# the player has.
		
		real_amount = 
		case Player.bet(player, call_amount) do
			%Player{name: _, chips: _} -> call_amount
			:insufficient_chips -> 
				pl = AppState.get(player)
				Player.bet(player, pl.chips)
				TableManager.all_in(player)
				pl.chips
			_ -> raise "Something went wrong in Player.bet"
		end
		
		# real_amount is the number of chips that will be used to calculate
		# the additional chips placed into the pot by the player and will
		# be used to update the BetServer round and paid lists with the 
		# appropriate amount of chips for the given player. The amount
		# passed in as the third argument will be used simply for 
		# updating the to_call amount in the BetServer. This is 
		# is the amount that will be displayed to users when playing
		# the game, (i.e. if the amount is 70, but the player has already
		# paid 20 during the round, the player will "raise to 70", but will
		# not have to sacrifice the 20 chips put in earlier.)
		
		BetServer.bet(player, real_amount, amount)
		TableManager.advance
		
		game = %{game | called: [player]}
	end
	
	def reset_called(game) do
		%{game | called: []}
	end
	
end