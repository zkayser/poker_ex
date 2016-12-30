defmodule PokerEx.TableManagerTest do
	use ExUnit.Case
	alias PokerEx.TableManager
	
	@players ["a", "b", "c"]
	
	setup do
		{:ok, pid} = TableManager.start_link(@players)
		
		on_exit fn ->
			Process.exit(pid, :kill)
		end
		
		[pid: pid]
	end
	
	test "starting TableManager starts a new process", context do
		assert is_pid(context[:pid])
	end
	
	test "initializing the TableManager with players should place the players in the seating list with seat numbers", context do
		state = TableManager.fetch_data(context[:pid])
		assert state.seating == Enum.with_index(@players)
		assert state.active == []
	end
	
	test "seating a new player before starting a round should place the player in the seating list with the proper seat number", context do
		TableManager.seat_player(context[:pid], "d")
		state = TableManager.fetch_data(context[:pid])
		last = List.last(state.seating)
		assert last == {"d", 3}
		assert state.active == []
	end
	
	test "removing a player before starting a round should remove the player from the seating list and adjust the seating numbers", context do
		TableManager.remove_player(context[:pid], "b")
		state = TableManager.fetch_data(context[:pid])
		expected = [{"a", 0}, {"c", 1}]
		assert state.seating == expected
	end
	
	test "starting a round should move the seated players into the active list", context do
		TableManager.start_round(context[:pid])
		state = TableManager.fetch_data(context[:pid])
		assert length(state.active) == 3
	end
	
	test "starting a round should setup the big_blind and small_blind", context do
		TableManager.start_round(context[:pid])
		state = TableManager.fetch_data(context[:pid])
		assert state.big_blind == "a"
		assert state.small_blind == "b"
		assert state.current_big_blind == 0
		assert state.current_small_blind == 1
	end
	
	test "starting a round should properly set the current player", context do
		TableManager.start_round(context[:pid])
		state = TableManager.fetch_data(context[:pid])
		assert state.current_player == {"c", 2}
	end
	
	test "starting a round should properly set the next player with wraparound", context do
		TableManager.start_round(context[:pid])
		state = TableManager.fetch_data(context[:pid])
		assert state.next_player == {"b", 1}
	end
	
	test "starting a round should properly set the next player without wraparound", context do
		TableManager.seat_player(context[:pid], "d")
		TableManager.start_round(context[:pid])
		state = TableManager.fetch_data(context[:pid])
		assert state.next_player == {"d", 3}
	end
	
	test "advance should rotate the next_player to be the current_player", context do
		TableManager.start_round(context[:pid])
		state = TableManager.fetch_data(context[:pid])
		up_next = state.next_player
		TableManager.advance(context[:pid])
		new_state = TableManager.fetch_data(context[:pid])
		
		assert new_state.current_player == up_next
	end
	
	test "only the current player should be able to fold", context do
		TableManager.start_round(context[:pid])
		TableManager.fold(context[:pid], "c")
		state = TableManager.fetch_data(context[:pid])
		refute {"c", 2} in state.active
	end
	
	test "when the current player folds, the current_player and next_player should be updated properly", context do
		TableManager.start_round(context[:pid])
		TableManager.fold(context[:pid], "c")
		state = TableManager.fetch_data(context[:pid])
		assert state.current_player == {"b", 1}
		assert state.next_player == {"a", 0}
	end
	
	test "the advance cycle works properly when a player folds in the middle of the list", context do
		TableManager.start_round(context[:pid])
		TableManager.advance(context[:pid])
		TableManager.advance(context[:pid])
		TableManager.fold(context[:pid], "a")
		TableManager.advance(context[:pid])
		TableManager.advance(context[:pid])
		state = TableManager.fetch_data(context[:pid])
		
		assert state.current_player == {"c", 2}
		assert state.next_player == {"b", 1}
	end
	
	test "starting a round, then calling clear_round and start_round again should properly update the big_blind and small_blind", context do
		TableManager.start_round(context[:pid])
		TableManager.clear_round(context[:pid])
		TableManager.start_round(context[:pid])
		state = TableManager.fetch_data(context[:pid])
		
		assert state.big_blind == "b"
		assert state.small_blind == "c"
		assert state.current_big_blind == 1
		assert state.current_small_blind == 2
	end
	
	test "clearing round and starting a new round should properly update the current_player and next_player", context do
		TableManager.start_round(context[:pid])
		TableManager.clear_round(context[:pid])
		TableManager.start_round(context[:pid])
		state = TableManager.fetch_data(context[:pid])
		
		assert state.current_player == {"a", 0}
		assert state.next_player == {"b", 1}
	end
	
	test "when remove_player is called it should remove the player from both the active and seating lists", context do
		TableManager.start_round(context[:pid])
		TableManager.remove_player(context[:pid], "c")
		state = TableManager.fetch_data(context[:pid])
		
		assert state.active == [{"b", 1}, {"a", 0}]
		refute {"c", 2} in state.seating
		refute {"c", 2} in state.active
	end
	
	test "joining players half way through a round and then starting a new round does not ruin the turn order", context do
		TableManager.start_round(context[:pid])
		TableManager.fold(context[:pid], "c")
		TableManager.seat_player(context[:pid], "d")
		TableManager.fold(context[:pid], "b")
		TableManager.clear_round(context[:pid])
		TableManager.start_round(context[:pid])
		state = TableManager.fetch_data(context[:pid])
		assert {"d", 3} in state.active
	end
end