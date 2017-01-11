defmodule PokerEx.BetServer do
	use GenServer
	
	alias PokerEx.BetHistory, as: History
	alias PokerEx.Events

	def start_link do
		GenServer.start_link(__MODULE__, [])
	end
	
	#######################
	# Interface functions #
	#######################
	
	def bet(pid, player, real_amount, amount) do
		GenServer.call(pid, {:bet, player, real_amount, amount})
	end
	
	def fetch_data(pid) do
		GenServer.call(pid, :fetch_data)
	end
	
	def paid(pid) do
		GenServer.call(pid, :paid)
	end
	
	def pot(pid) do
		GenServer.call(pid, :pot)
	end
	
	def get_paid_in_round(pid, player) do
		GenServer.call(pid, {:get_paid_in_round, player})
	end
	
	def get_to_call(pid) do
		GenServer.call(pid, :get_to_call)
	end
	
	def reset_round(pid) do
		GenServer.cast(pid, :reset_round)
	end
	
	def clear(pid) do
		GenServer.cast(pid, :clear)
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
		Events.paid_in_round_update(updated_round)
		{:reply, update, update}
	end
	
	def handle_call({:bet, player, real_amount, amount}, _from, %History{to_call: to_call, paid: paid, pot: pot, round: round} = history) when amount > to_call do
		updated_paid = update_total_paid(player, paid, real_amount)
		updated_round = update_paid_in_round(player, round, real_amount)
			
		update = %History{ history | paid: updated_paid, to_call: amount, pot: pot + real_amount, round: updated_round}
		Events.paid_in_round_update(updated_round)
		Events.call_amount_update(update.to_call)
		{:reply, update, update}
	end
	
	def handle_call(:fetch_data, _from, history) do
		{:reply, history, history}
	end
	
	def handle_call(:paid, _from, %History{paid: paid} = history) do
		{:reply, paid, history}
	end
	
	def handle_call(:pot, _from, %History{pot: pot} = history) do
		{:reply, pot, history}
	end
	
	def handle_call({:get_paid_in_round, player}, _from, %History{round: round} = history) do
		{:reply, Map.get(round, player), history}
	end
	
	def handle_call(:get_to_call, _from, %History{to_call: to_call} = history) do
		{:reply, to_call, history}
	end
	
	def handle_cast(:reset_round, history) do
		Events.call_amount_update(0)
		{:noreply, %History{ history | round: %{}, to_call: 0} }
	end
	
	def handle_cast(:clear, _history) do
		Events.call_amount_update(0)
		{:noreply, %History{to_call: 0, pot: 0}}
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