defmodule PokerEx.RoomTest do
	use ExUnit.Case
	alias PokerEx.Room, as: Room
	alias PokerEx.Player
	alias PokerEx.AppState
	alias PokerEx.BetServer
	alias PokerEx.HandServer
	alias PokerEx.TableManager
	
	setup do
		room = 
			case Room.start_link do
				{:ok, pid} -> pid
				{:error, _} -> Process.whereis(:room)
			end
		players = [p1, p2, p3, p4] = 1..4 |> Enum.to_list |> Enum.map(fn num -> Player.new("#{num}") end)
		Enum.each(players, fn p -> AppState.put(p) end)
		table = Room.data.table_manager
		hands = Room.data.hand_server
		bets = Room.data.bet_server
		
		on_exit fn -> Process.exit(room, :kill) end
		on_exit fn -> Enum.each(players, fn p -> AppState.delete(p) end) end
		
		[room: room, players: players, p1: p1, p2: p2, p3: p3, p4: p4, table: table, hands: hands, bets: bets]
	end
	
	test "the room starts", context do
		assert is_pid(context[:room])
	end
	
	test "players can join the room", context do
		player = context[:p1]
		Room.join(player)
		assert {player.name, 0} in TableManager.seating(context[:table])
	end
	
	test "when a second player joins the room, a game begins", context do
		p1 = context[:p1]
		p2 = context[:p2]
		Room.join(p1)
		Room.join(p2)
		assert length(HandServer.player_hands(context[:hands])) == 2
	end
	
	test "player 2 should be able to make a move when the game begins", context do
		p1 = context[:p1]
		p2 = context[:p2]
		Room.join(p1)
		Room.join(p2)
		Room.raise(p2, 20)
		assert BetServer.fetch_data(context[:bets]).round[p2.name] == 20
	end
	
	test "blinds should be taken when the game begins", context do
		Room.join(context[:p1])
		Room.join(context[:p2])
		assert BetServer.fetch_data(context[:bets]).pot == 15
	end
	
	describe "SIMPLE GAME:" do
		test "a simple game with only raises and call should not raise any errors", context do
			p1 = context[:p1]
			p2 = context[:p2]
			Room.join(p1)
			Room.join(p2)
			1..3 |> Enum.to_list |> Enum.each(
				fn _ -> 
					Room.raise(p2, 20) 
					Room.call(p2)
				end)
			Room.raise(p2, 20)
			Room.call(p1)
			assert HandServer.stats(context[:hands]) == []
		end
	end
	
	test "a player should be able to join the room in the middle of an ongoing hand", context do
		[p1, p2, p3, _] = context[:players]
		Room.join(p1)
		Room.join(p2)
		Room.raise(p2, 20)
		Room.join(p3)
		Room.call(p1)
		assert TableManager.seating(context[:table]) == [{p1.name, 0}, {p2.name, 1}, {p3.name, 2}]
	end
	
	describe "FOLD:" do
	
		test "a player should be able to fold in the flop state", context do
			[p1, p2|_] = context[:players]
			chips_start = AppState.get(p2.name).chips
			Room.join(p1)
			Room.join(p2)
			Room.raise(p2, 20)
			Room.call(p1)
			Room.raise(p2, 20)
			pot = BetServer.pot(context[:bets])
			result = Room.fold(p1)
			Process.sleep(100)
			chips_end = AppState.get(p2.name).chips
			assert result == {"#{p2.name} wins the pot on fold", pot}
			assert chips_start < chips_end
		end
		
		test "a player should be able to fold in the turn state", context do
			[p1, p2|_] = context[:players]
			chips_start = AppState.get(p2.name).chips
			Room.join(p1)
			Room.join(p2)
			1..2 |> Enum.to_list |> Enum.map(
				fn _ -> 
					Room.raise(p2, 20)
					Room.call(p1)
				end)
			Room.raise(p2, 20)
			pot = BetServer.pot(context[:bets])
			result = Room.fold(p1)
			Process.sleep(100)
			chips_end = AppState.get(p2.name).chips
			assert result == {"#{p2.name} wins the pot on fold", pot}
			assert chips_start < chips_end
		end
	
		test "a player should be able to fold in the river state", context do
			[p1, p2|_] = context[:players]
			chips_start = AppState.get(p2.name).chips
			Room.join(p1)
			Room.join(p2)
			1..3 |> Enum.to_list |> Enum.map(
				fn _ ->
					Room.raise(p2, 20)
					Room.call(p1)
				end)
			Room.raise(p2, 20)
			result = Room.fold(p1)
			pot = BetServer.pot(context[:bets])
			Process.sleep(100)
			chips_end = AppState.get(p2.name).chips
			assert result == {"#{p2.name} wins the pot on fold", pot}
			assert chips_start < chips_end
		end
	end
	
	test "auto-complete should kick in when both players go all in in a two-person game", context do
		[p1, p2|_] = context[:players]
		Room.join(p1)
		Room.join(p2)
		Room.raise(p2, 1000)
		{result, _string} = Room.call(p1)
		assert result == :game_finished
	end
	
	describe "AUTO_COMPLETE IN PRE_FLOP STATE:" do
		setup [:play_initial_round_and_join_all]
		
		test "auto-complete works when all players go all in", context do
			# Raising 1200 ensures that the player will go all in
			Room.raise(context[:current], 1200)
			Room.call(context[:next])
			Room.call(context[:on_deck])
			{result, _string} = Room.call(context[:last])
			assert result == :game_finished
		end
		
		test "auto-complete works when one player goes all in, one calls, and the remaining fold", context do
			Room.raise(context[:current], 1200)
			Room.fold(context[:next])
			Room.fold(context[:on_deck])
			{result, _string} = Room.call(context[:last])
			assert result == :game_finished
		end
	end
	
	describe "auto-complete in flop state" do
		setup [:play_initial_round_and_join_all, :simulate_pre_flop_betting]
		
		test "auto-complete works when all players go all in", context do
			# Put current player all in
			Room.raise(context[:current], 1200)
			Room.call(context[:next])
			Room.call(context[:on_deck])
			{result, _string} = Room.call(context[:last])
			assert result == :game_finished
		end
		
		test "auto-complete works when one player goes all in, one calls, and the remaining fold", context do
			Room.raise(context[:current], 1200)
			Room.call(context[:next])
			Room.fold(context[:on_deck])
			{result, _string} = Room.fold(context[:last])
			assert result == :game_finished
		end
		
		test "auto-complete works when one player goes all in, the players in the middle fold, and the last player calls", context do
			Room.raise(context[:current], 1200)
			Room.fold(context[:next])
			Room.fold(context[:on_deck])
			{result, _string} = Room.call(context[:last])
			assert result == :game_finished
		end
		
		test "auto-complete works when the first player raises, the next player goes all in, the remaining two fold, and the first player calls", context do
			Room.raise(context[:current], 20)
			Room.raise(context[:next], 1200)
			Room.fold(context[:on_deck])
			Room.fold(context[:last])
			{result, _string} = Room.call(context[:current])
			assert result == :game_finished
		end
	end
	
	defp play_initial_round_and_join_all(context) do
		Enum.each(context[:players], fn p -> Room.join(p) end)
		# Play first round
		Room.raise(context[:p2], 20)
		Room.fold(context[:p1])
		[{current, _}, {next, _}, {on_deck, _}, {last, _}] = Room.active
		[current: AppState.get(current), next: AppState.get(next), on_deck: AppState.get(on_deck), last: AppState.get(last)]
	end
	
	defp simulate_pre_flop_betting(context) do
		Room.raise(context[:current], 20)
		Room.call(context[:next])
		Room.call(context[:on_deck])
		Room.call(context[:last])
		context
	end
end