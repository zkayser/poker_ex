defmodule PokerEx.BetServerTest do
	use ExUnit.Case
	
	alias PokerEx.BetServer
	alias PokerEx.BetHistory, as: History
	
	setup do
		{:ok, pid} = BetServer.start_link(15)
		
		on_exit fn ->
			Process.exit(pid, :kill)
		end
		
		[pid: pid]
	end
	
	test "calling reward when there are no side pots and only one winner rewards the winner" do
		history = %History{bets_from: [{"a", 300}, {"b", 300}, {"c", 300}, {"d", 20}, {"e", 0}]}
		{:reply, update, update} = BetServer.handle_call({:reward, "a"}, 1, history)
		assert
	end


	defmodule Player.Mock do
		
	end
end