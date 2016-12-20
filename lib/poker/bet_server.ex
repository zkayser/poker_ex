defmodule PokerEx.BetServer do
	use GenServer
	
	alias PokerEx.BetHistory, as: History
	alias PokerEx.Player
	alias PokerEx.RewardManager
	
	@name :bet_server
	
	def start_link do
		GenServer.start_link(__MODULE__, [], name: @name)
	end
	
	#######################
	# Interface functions #
	#######################
	
	def bet(player, real_amount, amount) do
		GenServer.call(@name, {:bet, player, real_amount, amount})
	end
	
	def fetch_data do
		GenServer.call(@name, :fetch_data)
	end
	
	def get_paid_in_round(player) do
		GenServer.call(@name, {:get_paid_in_round, player})
	end
	
	def get_to_call do
		GenServer.call(@name, :get_to_call)
	end
	
	def reset_round do
		GenServer.cast(@name, :reset_round)
	end
	
	#############
	# Callbacks #
	#############
	
	def init([]) do
		{:ok, %History{to_call: 0}}
	end
	
	def handle_call({:bet, player, real_amount, amount}, _from, %History{to_call: to_call, paid: paid, round: round, pot: pot} = history) when amount <= to_call do
		updated_paid = update_total_paid(player, paid, real_amount)
		updated_round = update_paid_in_round(player, round, real_amount)	
		
		update = %History{ history | paid: updated_paid, pot: pot + real_amount, round: updated_round}
		
		{:reply, update, update}
	end
	
	def handle_call({:bet, player, real_amount, amount}, _from, %History{to_call: to_call, paid: paid, pot: pot, round: round} = history) when amount > to_call do
		updated_paid = update_total_paid(player, paid, real_amount)
		updated_round = update_paid_in_round(player, round, real_amount)
			
		update = %History{ history | paid: updated_paid, to_call: amount, pot: pot + real_amount, round: updated_round}
		{:reply, update, update}
	end
	
	def handle_call(:fetch_data, _from, history) do
		{:reply, history, history}
	end
	
	def handle_call({:get_paid_in_round, player}, _from, %History{round: round} = history) do
		{:reply, Map.get(round, player), history}
	end
	
	def handle_call(:get_to_call, _from, %History{to_call: to_call} = history) do
		{:reply, to_call, history}
	end
	
	## Move to higher level -> Game.ex
	#def handle_call({:reward, hand_rankings}, _from, %History{paid: paid} = history) do
	#	rewards = RewardManager.manage_rewards(hand_rankings, Map.to_list(paid))
	#	{:reply, rewards, %History{ history | rewards: rewards }}
	#end
	
	def handle_cast(:reset_round, history) do
		{:noreply, %History{ history | round: %{}, to_call: 0} }
	end
	
	#####################
	# Utility functions #
	#####################
	
	defp update_total_paid(player, paid, amount) do
		Map.update(paid, player, amount, fn current -> current + amount end)
	end
	
	defp update_paid_in_round(player, round, amount) do
		Map.update(round, player, amount, fn v -> v + amount end)
	end
	
end