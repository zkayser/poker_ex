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
	
	test "initializing the TableManager with players should place the players in the seating list with seat numbers" do
		state = TableManager.fetch_data
		assert state.seating == Enum.with_index(@players)
		assert state.active == []
	end
	
	test "seating a new player before starting a round should place the player in the seating list with the proper seat number" do
		TableManager.seat_player("d")
		state = TableManager.fetch_data
		last = List.last(state.seating)
		assert last == {"d", 3}
		assert state.active == []
	end
	
	test "removing a player before starting a round should remove the player from the seating list and adjust the seating numbers" do
		TableManager.remove_player("b")
		state = TableManager.fetch_data
		expected = [{"a", 0}, {"c", 1}]
		assert state.seating == expected
	end
	
	test "starting a round should move the seated players into the active list" do
		TableManager.start_round
		state = TableManager.fetch_data
		assert length(state.active) == 3
	end
	
	test "starting a round should setup the big_blind and small_blind" do
		TableManager.start_round
		state = TableManager.fetch_data
		assert state.big_blind == "a"
		assert state.small_blind == "b"
		assert state.current_big_blind == 0
		assert state.current_small_blind == 1
	end
	
	test "starting a round should properly set the current player" do
		TableManager.start_round
		state = TableManager.fetch_data
		assert state.current_player == {"c", 2}
	end
	
	test "starting a round should properly set the next player with wraparound" do
		TableManager.start_round
		state = TableManager.fetch_data
		assert state.next_player == {"b", 1}
	end
	
	test "starting a round should properly set the next player without wraparound" do
		TableManager.seat_player("d")
		TableManager.start_round
		state = TableManager.fetch_data
		assert state.next_player == {"d", 3}
	end
	
	test "advance should rotate the next_player to be the current_player" do
		TableManager.start_round
		state = TableManager.fetch_data
		up_next = state.next_player
		TableManager.advance
		new_state = TableManager.fetch_data
		
		assert new_state.current_player == up_next
	end
	
	test "only the current player should be able to fold" do
		TableManager.start_round
		TableManager.fold("c")
		state = TableManager.fetch_data
		refute {"c", 2} in state.active
	end
	
	test "when the current player folds, the current_player and next_player should be updated properly" do
		TableManager.start_round
		TableManager.fold("c")
		state = TableManager.fetch_data
		assert state.current_player == {"b", 1}
		assert state.next_player == {"a", 0}
	end
	
	test "the advance cycle works properly when a player folds in the middle of the list" do
		TableManager.start_round
		TableManager.advance
		TableManager.advance
		TableManager.fold("a")
		TableManager.advance
		TableManager.advance
		state = TableManager.fetch_data
		
		assert state.current_player == {"c", 2}
		assert state.next_player == {"b", 1}
	end
	
	test "starting a round, then calling clear_round and start_round again should properly update the big_blind and small_blind" do
		TableManager.start_round
		TableManager.clear_round
		TableManager.start_round
		state = TableManager.fetch_data
		
		assert state.big_blind == "b"
		assert state.small_blind == "c"
		assert state.current_big_blind == 1
		assert state.current_small_blind == 2
	end
	
	test "clearing round and starting a new round should properly update the current_player and next_player" do
		TableManager.start_round
		TableManager.clear_round
		TableManager.start_round
		state = TableManager.fetch_data
		
		assert state.current_player == {"a", 0}
		assert state.next_player == {"b", 1}
	end
	
	test "when remove_player is called it should remove the player from both the active and seating lists" do
		TableManager.start_round
		TableManager.remove_player("c")
		state = TableManager.fetch_data
		
		assert state.active == [{"b", 1}, {"a", 0}]
		refute {"c", 2} in state.seating
		refute {"c", 2} in state.active
	end
	
	test "joining players half way through a round and then starting a new round does not ruin the turn order" do
		TableManager.start_round
		TableManager.fold("c")
		TableManager.seat_player("d")
		TableManager.fold("b")
		TableManager.clear_round
		TableManager.start_round
		state = TableManager.fetch_data
		assert {"d", 3} in state.active
	end
end