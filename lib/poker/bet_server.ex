defmodule PokerEx.BetServer do
	use GenServer
	
	alias PokerEx.BetHistory, as: History
	alias PokerEx.Player
	alias PokerEx.RewardManager
	
	@name :bet_server
	
	def start_link(to_call) do
		GenServer.start_link(__MODULE__, [to_call], name: @name)
	end
	
	#######################
	# Interface functions #
	#######################
	
	def bet(player, amount) do
		GenServer.call(@name, {:bet, player, amount})
	end
	
	def reward(player, num_callers, num_winners) do
		GenServer.call(@name, {:reward, player, num_winners})
	end
	
	#############
	# Callbacks #
	#############
	
	def init([to_call]) do
		{:ok, %History{to_call: to_call}}
	end
	
	def handle_call({:bet, player, amount}, _from, %History{to_call: to_call, paid: paid} = history) when amount <= to_call do
		{^player, current} = Enum.find(paid, fn {name, _} -> name == player end)
		
		updated_paid = 
			paid
			|> Enum.reject(fn {name, _} -> name == player end)
			|> Kernel.++([{player, current + amount}])
			
		update = %History{ history | paid: updated_paid}
		
		{:reply, update, update}
	end
	
	def handle_call({:bet, player, amount}, _from, %History{to_call: to_call, paid: paid} = history) when amount > to_call do
		{^player, current} = Enum.find(paid, fn {name, _} -> name == player end)
		
		updated_paid =
			paid
			|> Enum.reject(fn {name, _} -> name == player end)
			|> Kernel.++([{player, current + amount}])
	end
	
	def handle_call({:reward, hand_rankings}, _from, %History{paid: paid} = history) do
		rewards = RewardManager.manage_rewards(hand_rankings, paid)
		{:reply, rewards, %History{ history | rewards: rewards }}
	end
	
	#####################
	# Utility functions #
	#####################
	
	defp update_current(player, amount, map) do
		Map.put(map, player, amount)
	end
	
	defp update_paid_in_round(player, amount, map) do
		Map.update(map, player, amount, fn v -> v + amount end)
	end
	
end