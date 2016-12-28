defmodule PokerEx.Room do
	alias PokerEx.BetBuffer, as: Buffer
	alias PokerEx.BetServer
	alias PokerEx.BetHistory, as: History
	alias PokerEx.Player
	alias PokerEx.TableManager, as: Manager
	alias PokerEx.TableState, as: State
	alias PokerEx.HandServer, as: Server
	alias PokerEx.RewardManager
	alias PokerEx.Room, as: Room
	
	defstruct buffer: %{called: []}, table_state: %State{}, bet_history: %History{}, hands: %Server{},
						bet_server: nil, hand_server: nil, table_manager: nil
	
	@name :room
	@big_blind 10
	@small_blind 5
	
	def start_link do
		:gen_statem.start_link({:local, @name}, __MODULE__, [], [])
	end
	
	##############
	# Client API #
	##############
	
	def join(player) do
		:gen_statem.call(@name, {:join, player.name})
	end
	
	def call_pot(player) do
		:gen_statem.call(@name, {:call_pot, player.name})
	end
	
	def check(player) do
		:gen_statem.call(@name, {:check, player.name})
	end
	
	def raise_pot(player, amount) do
		:gen_statem.call(@name, {:raise_pot, player.name, amount})
	end
	
	def fold(player) do
		:gen_statem.call(@name, {:fold, player.name})
	end
	
	def auto_complete do
		:gen_statem.call(@name, :auto_complete)
	end
	
	def ready(player) do
		:gen_statem.call(@name, {:ready, player.name})
	end
	
	def leave(player) do
		:gen_statem.call(@name, {:leave, player.name})
	end
	
	def get_state do
		:gen_statem.call(@name, :get_state)
	end
	
	def clear do
		:gen_statem.cast(@name, :clear)
	end
	
	######################
	# Callback Functions #
	######################
	
	def terminate(_reason, _state, _data) do
		:void
	end
	
	def code_change(_vsn, state, data, _extra) do
		{:ok, state, data}
	end
	
	def init(_) do
		send(self, :setup)
		{:ok, :idle, %Room{}}
	end
	
	def callback_mode do
		:state_functions
	end
	
	###################
	# State Functions #
	###################
	
	######## IDLE STATE ###########
	
	def idle({:call, from}, {:join, player}, %Room{buffer: buffer} = data) do
		Manager.seat_player(player)
		
		case length(Manager.fetch_data.seating) do
			x when x > 1 ->
				Manager.start_round
				Buffer.raise_pot(buffer, Manager.get_small_blind, @small_blind, 0)
				Buffer.raise_pot(buffer, Manager.get_big_blind, @big_blind, BetServer.get_to_call)
				update = 
					%Room{ data | table_state: Manager.fetch_data, hands: Server.deal_first_hand(Manager.players_only),
								 bet_history: BetServer.fetch_data
					}
				{:next_state, :pre_flop, update, [{:reply, from, update}]}
			_ -> 
				{:next_state, :idle, %Room{ data | table_state: Manager.fetch_data}, [{:reply, from, "Player joined: #{player}"}]}
		end
	end
	
	def idle(event_type, event_content, data) do
		handle_event(event_type, event_content, data)
	end
	
	########## PRE_FLOP STATE #############
	
	def pre_flop({:call, from}, {:call_pot, player}, %Room{buffer: %{called: called} = buffer} = data) do
		case length(Manager.get_active) - 1 > length(called) do
			true ->
				buffer = Buffer.call(buffer, player)
				update = %Room{ data | buffer: buffer, bet_history: BetServer.fetch_data, table_state: Manager.fetch_data}
				{:next_state, :pre_flop, update, [{:reply, from, update}]}
			_ ->
				if length(Manager.get_active) == 1 && length(Manager.get_all_in) > 0 do
					buffer = Buffer.call(buffer, player)
					update = %Room{ data | buffer: buffer, bet_history: BetServer.fetch_data, table_state: Manager.fetch_data, hands: Server.fetch_data}
					{:next_state, :game_over, update, [{:reply, from, "Auto-complete initiated..."}, {:next_event, :internal, {:auto_complete, from}}]}
				else
					buffer = Buffer.call(buffer, player)
					updated_buffer = Buffer.reset_called(buffer)
					Manager.reset_turns
					Server.deal_flop
					BetServer.reset_round
					update = %Room{ data | buffer: updated_buffer, table_state: Manager.fetch_data, bet_history: BetServer.fetch_data, hands: Server.fetch_data}
					{:next_state, :flop, update, [{:reply, from, update}]}
				end
		end
	end
	
	def pre_flop({:call, from}, {:raise_pot, player, amount}, %Room{buffer: buffer} = data) do
		case amount > BetServer.get_to_call do
			true ->
				buffer = Buffer.raise_pot(buffer, player, amount, BetServer.get_to_call)
				update = %Room{ data | buffer: buffer, bet_history: BetServer.fetch_data, table_state: Manager.fetch_data}
				{:next_state, :pre_flop, update, [{:reply, from, update}]}
			_ ->
				{:next_state, :pre_flop, data, [{:reply, from, "#{player} tried to raise but did not cover #{BetServer.get_to_call}"}]}
		end
	end
	
	def pre_flop({:call, from}, {:check, player}, %Room{buffer: %{called: called} = buffer} = data) do
		case length(Manager.get_active) - 1 > length(called) do
			true ->
				buffer = Buffer.check(buffer, player, BetServer.get_paid_in_round(player), BetServer.get_to_call)
				update = %Room{ data | buffer: buffer, bet_history: BetServer.fetch_data, table_state: Manager.fetch_data}
				{:next_state, :pre_flop, update, [{:reply, from, update}]}
			_ ->
				buffer = Buffer.check(buffer, player, BetServer.get_paid_in_round(player), BetServer.get_to_call)
				Manager.reset_turns
				Server.deal_flop
				BetServer.reset_round
				update = %Room{ data | buffer: buffer, bet_history: BetServer.fetch_data, table_state: Manager.fetch_data, hands: Server.fetch_data}
				{:next_state, :flop, update, [{:reply, from, update}]}
		end
	end
	
	def pre_flop({:call, from}, {:fold, player}, %Room{buffer: buffer} = data) do
		case length(Manager.get_active) > 2 do
			true ->
				update = %Room{ data | table_state: Manager.fold(player)}
				{:next_state, :pre_flop, update, [{:reply, from, update}]}
			_ ->
				if length(Manager.get_all_in) > 0 do
					unless length(Manager.get_active) == 2 do
						{:next_state, :game_over, data, [{:reply, from, "Auto complete initiated..."}, {:next_event, :internal, {:auto_complete, from}}]}
					else 
						{:next_state, :pre_flop, %Room{ data | table_state: Manager.fold(player)}, [{:reply, from, "#{player} folded"}]}
					end
				else
					Manager.fold(player)
					[{winner, _seat}|_] = Manager.get_active
					update = %Room{ data | buffer: Map.put(buffer, :winner, winner)}
					{:next_state, :game_over, update, [{:reply, from, "#{winner} wins the pot on fold"}, {:next_event, :internal, :reward_winner}]}
				end
		end
	end
	
	def pre_flop({:call, from}, :auto_complete, data) do
		Server.deal_flop
		Server.deal_one
		Server.deal_one
		update = %Room{ data | bet_history: BetServer.fetch_data, table_state: Manager.fetch_data, hands: Server.fetch_data}
		{:next_state, :game_over, update, [{:reply, from, "Auto complete initiated..."}, {:next_event, :internal, :reward_winner}]}
	end
	
	def pre_flop(event_type, event_content, data) do
		handle_event(event_type, event_content, data)
	end
	
	########## FLOP STATE #############
	
	def flop({:call, from}, {:call_pot, player}, %Room{buffer: %{called: called} = buffer} = data) do
		case length(Manager.get_active) - 1 > length(called) do
			true ->
				buffer = Buffer.call(buffer, player)
				update = %Room{ data | buffer: buffer, bet_history: BetServer.fetch_data, table_state: Manager.fetch_data}
				{:next_state, :flop, update, [{:reply, from, update}]}
			_ ->
				if length(Manager.get_active) == 1 && length(Manager.get_all_in) > 0 do
					buffer = Buffer.call(buffer, player)
					update = %Room{ data | buffer: buffer, bet_history: BetServer.fetch_data, table_state: Manager.fetch_data, hands: Server.fetch_data}
					{:next_state, :game_over, update, [{:reply, from, "Auto-complete initiated..."}, {:next_event, :internal, {:auto_complete, from}}]}
				else
					buffer = Buffer.call(buffer, player)
					updated_buffer = Buffer.reset_called(buffer)
					Manager.reset_turns
					Server.deal_one
					BetServer.reset_round
					update = %Room{ data | buffer: updated_buffer, table_state: Manager.fetch_data, bet_history: BetServer.fetch_data, hands: Server.fetch_data}
					{:next_state, :turn, update, [{:reply, from, update}]}
				end
		end
	end
	
	def flop({:call, from}, {:raise_pot, player, amount}, %Room{buffer: buffer} = data) do
		case amount > BetServer.get_to_call do
			true ->
				buffer = Buffer.raise_pot(buffer, player, amount, BetServer.get_to_call)
				update = %Room{ data | buffer: buffer, bet_history: BetServer.fetch_data, table_state: Manager.fetch_data}
				{:next_state, :flop, update, [{:reply, from, update}]}
			_ ->
				{:next_state, :flop, data, [{:reply, from, "#{player} tried to raise but did not cover #{BetServer.get_to_call}"}]}
		end
	end
	
	def flop({:call, from}, {:check, player}, %Room{buffer: %{called: called} = buffer} = data) do
		case length(Manager.get_active) - 1 > length(called) do
			true ->
				buffer = Buffer.check(buffer, player, BetServer.get_paid_in_round(player), BetServer.get_to_call)
				update = %Room{ data | buffer: buffer, bet_history: BetServer.fetch_data, table_state: Manager.fetch_data}
				{:next_state, :flop, update, [{:reply, from, update}]}
			_ ->
				buffer = Buffer.check(buffer, player, BetServer.get_paid_in_round(player), BetServer.get_to_call)
				Manager.reset_turns
				Server.deal_one
				BetServer.reset_round
				update = %Room{ data | buffer: buffer, bet_history: BetServer.fetch_data, table_state: Manager.fetch_data, hands: Server.fetch_data}
				{:next_state, :turn, update, [{:reply, from, update}]}
		end
	end
	
	def flop({:call, from}, {:fold, player}, %Room{buffer: buffer} = data) do
		case length(Manager.get_active) > 2 do
			true ->
				update = %Room{ data | table_state: Manager.fold(player), bet_history: BetServer.fetch_data}
				{:next_state, :flop, update, [{:reply, from, update}]}
			_ ->
				if length(Manager.get_all_in) > 0 do
					unless length(Manager.get_active) == 2 do
						{:next_state, :game_over, data, [{:reply, from, "Auto complete initiated..."}, {:next_event, :internal, {:auto_complete, from}}]}
					else 
						{:next_state, :flop, %Room{ data | table_state: Manager.fold(player)}, [{:reply, from, "#{player} folded"}]}
					end
				else
					Manager.fold(player)
					[{winner, _seat}|_] = Manager.get_active
					update = %Room{ data | buffer: Map.put(buffer, :winner, winner)}
					{:next_state, :game_over, update, [{:reply, from, "#{winner} wins the pot on fold"}, {:next_event, :internal, :reward_winner}]}
				end
		end
	end
	
	def flop({:call, from}, :auto_complete, data) do
		Server.deal_one
		Server.deal_one
		update = %Room{ data | bet_history: BetServer.fetch_data, table_state: Manager.fetch_data, hands: Server.fetch_data}
		{:next_state, :game_over, update, [{:reply, from, "Auto complete initiated..."}, {:next_event, :internal, :reward_winner}]}
	end
	
	def flop(event_type, event_content, data) do
		handle_event(event_type, event_content, data)
	end
	
	############ TURN STATE ##################
	
	def turn({:call, from}, {:call_pot, player}, %Room{buffer: %{called: called} = buffer} = data) do
		case length(Manager.get_active) - 1 > length(called) do
			true ->
				buffer = Buffer.call(buffer, player)
				update = %Room{ data | buffer: buffer, bet_history: BetServer.fetch_data, table_state: Manager.fetch_data}
				{:next_state, :turn, update, [{:reply, from, update}]}
			_ ->
				if length(Manager.get_active) == 1 && length(Manager.get_all_in) > 0 do
					buffer = Buffer.call(buffer, player)
					update = %Room{ data | buffer: buffer, bet_history: BetServer.fetch_data, table_state: Manager.fetch_data, hands: Server.fetch_data}
					{:next_state, :game_over, update, [{:reply, from, "Auto-complete initiated..."}, {:next_event, :internal, {:auto_complete, from}}]}
				else
					buffer = Buffer.call(buffer, player)
					updated_buffer = Buffer.reset_called(buffer)
					Manager.reset_turns
					Server.deal_one
					BetServer.reset_round
					update = %Room{ data | buffer: updated_buffer, table_state: Manager.fetch_data, bet_history: BetServer.fetch_data, hands: Server.fetch_data}
					{:next_state, :river, update, [{:reply, from, update}]}
				end
		end
	end
	
	def turn({:call, from}, {:raise_pot, player, amount}, %Room{buffer: buffer} = data) do
		case amount > BetServer.get_to_call do
			true ->
				buffer = Buffer.raise_pot(buffer, player, amount, BetServer.get_to_call)
				update = %Room{ data | buffer: buffer, bet_history: BetServer.fetch_data, table_state: Manager.fetch_data}
				{:next_state, :turn, update, [{:reply, from, update}]}
			_ ->
				{:next_state, :turn, data, [{:reply, from, "#{player} tried to raise but did not raise above #{BetServer.get_to_call} chips"}]}
		end
	end
	
	def turn({:call, from}, {:check, player}, %Room{buffer: %{called: called} = buffer} = data) do
		case length(Manager.get_active) - 1 > length(called) do
			true ->
				buffer = Buffer.check(buffer, player, BetServer.get_paid_in_round(player), BetServer.get_to_call)
				update = %Room{ data | buffer: buffer, bet_history: BetServer.fetch_data, table_state: Manager.fetch_data}
				{:next_state, :turn, update, [{:reply, from, update}]}
			_ ->
				buffer = Buffer.check(buffer, player, BetServer.get_paid_in_round(player), BetServer.get_to_call)
				Manager.reset_turns
				Server.deal_one
				BetServer.reset_round
				update = %Room{ data | buffer: buffer, bet_history: BetServer.fetch_data, table_state: Manager.fetch_data, hands: Server.fetch_data}
				{:next_state, :river, update, [{:reply, from, update}]}
		end
	end
	
	def turn({:call, from}, {:fold, player}, %Room{buffer: buffer} = data) do
		case length(Manager.get_active) > 2 do
			true ->
				update = %Room{ data | table_state: Manager.fold(player), bet_history: BetServer.fetch_data}
				{:next_state, :turn, update, [{:reply, from, update}]}
			_ ->
				if length(Manager.get_all_in) > 0 do
					unless length(Manager.get_active) == 2 do
						{:next_state, :game_over, data, [{:reply, from, "Auto complete initiated..."}, {:next_event, :internal, {:auto_complete, from}}]}
					else 
						{:next_state, :turn, %Room{ data | table_state: Manager.fold(player)}, [{:reply, from, "#{player} folded"}]}
					end
				else
					Manager.fold(player)
					[{winner, _seat}|_] = Manager.get_active
					update = %Room{ data | buffer: Map.put(buffer, :winner, winner)}
					{:next_state, :game_over, update, [{:reply, from, "#{winner} wins the pot on fold"}, {:next_event, :internal, :reward_winner}]}
				end
		end
	end
	
	def turn({:call, from}, :auto_complete, data) do
		Server.deal_one
		update = %Room{ data | bet_history: BetServer.fetch_data, table_state: Manager.fetch_data, hands: Server.fetch_data}
		{:next_state, :game_over, update, [{:reply, from, "Auto complete initiated..."}, {:next_event, :internal, :reward_winner}]}
	end
	
	def turn(event_type, event_content, data) do
		handle_event(event_type, event_content, data)
	end
	
	############### RIVER STATE ##############
	
	def river({:call, from}, {:call_pot, player}, %Room{buffer: %{called: called} = buffer} = data) do
		case length(Manager.get_active) - 1 > length(called) do
			true ->
				buffer = Buffer.call(buffer, player)
				update = %Room{ data | buffer: buffer, bet_history: BetServer.fetch_data, table_state: Manager.fetch_data}
				{:next_state, :river, update, [{:reply, from, update}]}
			_ ->
				buffer = Buffer.call(buffer, player)
				updated_buffer = Buffer.reset_called(buffer)
				Server.score
				update = %Room{ data | buffer: updated_buffer, table_state: Manager.fetch_data, hands: Server.fetch_data, bet_history: BetServer.fetch_data}
				{:next_state, :game_over, update, [{:reply, from, update}, {:next_event, :internal, :reward_winner}]}
		end
	end
	
	def river({:call, from}, {:raise_pot, player, amount}, %Room{buffer: buffer} = data) do
		case amount > BetServer.get_to_call do
			true ->
				buffer = Buffer.raise_pot(buffer, player, amount, BetServer.get_to_call)
				update = %Room{ data | buffer: buffer, bet_history: BetServer.fetch_data, table_state: Manager.fetch_data}
				{:next_state, :river, update, [{:reply, from, update}]}
			_ ->
				{:next_state, :river, data, [{:reply, from, "#{player} tried to raise but did not cover #{BetServer.get_to_call}"}]}
		end
	end
	
	def river({:call, from}, {:check, player}, %Room{buffer: %{called: called} = buffer} = data) do
		case length(Manager.get_active) - 1 > length(called) do
			true ->
				buffer = Buffer.check(buffer, player, BetServer.get_paid_in_round(player), BetServer.get_to_call)
				update = %Room{ data | buffer: buffer, bet_history: BetServer.fetch_data, table_state: Manager.fetch_data}
				{:next_state, :river, update, [{:reply, from, update}]}
			_ ->
				buffer = Buffer.call(buffer, player)
				updated_buffer = Buffer.reset_called(buffer)
				Server.score
				update = %Room{ data | buffer: updated_buffer, table_state: Manager.fetch_data, hands: Server.fetch_data, bet_history: BetServer.fetch_data}
				{:next_state, :game_over, update, [{:reply, from, update}, {:next_event, :internal, :reward_winner}]}
		end
	end
	
	def river({:call, from}, {:fold, player}, %Room{buffer: buffer} = data) do
		case length(Manager.get_active) > 2 do
			true ->
				update = %Room{ data | table_state: Manager.fold(player), bet_history: BetServer.fetch_data}
				{:next_state, :river, update, [{:reply, from, update}]}
			_ ->
				if length(Manager.get_all_in) > 0 do
					unless length(Manager.get_active) == 2 do
						{:next_state, :game_over, data, [{:reply, from, "Auto complete initiated..."}, {:next_event, :internal, {:auto_complete, from}}]}
					else 
						{:next_state, :river, %Room{ data | table_state: Manager.fold(player)}, [{:reply, from, "#{player} folded"}]}
					end
				else
					Manager.fold(player)
					[{winner, _seat}|_] = Manager.get_active
					update = %Room{ data | buffer: Map.put(buffer, :winner, winner)}
					{:next_state, :game_over, update, [{:reply, from, "#{winner} wins the pot on fold"}, {:next_event, :internal, :reward_winner}]}
				end
		end
	end
	
	def river(event_type, event_content, data) do
		handle_event(event_type, event_content, data)
	end
	
	########## GAME OVER STATE ###############
	
	def game_over(:internal, :reward_winner, %Room{buffer: %{winner: winner}, bet_history: %History{pot: pot}}) when not is_nil(winner) do
		send(self, {:reward_winner, [{winner, 100}], pot})
		Manager.clear_round
		update = %Room{buffer: Buffer.new, table_state: Manager.fetch_data, hands: Server.fetch_data, bet_history: BetServer.fetch_data}
		{:next_state, :between_rounds, update, [{:next_event, :internal, :set_round}]} 
	end
	
	def game_over(:internal, :reward_winner, %Room{hands: %Server{stats: stats}, bet_history: %History{paid: paid}}) when not is_nil(stats) do
		send(self, {:reward_winner, stats, paid, Manager.get_active, Manager.get_all_in})
		Manager.clear_round
		update = %Room{buffer: Buffer.new, table_state: Manager.fetch_data, hands: %Server{}, bet_history: %History{}}
		{:next_state, :between_rounds, update, [{:next_event, :internal, :set_round}]}
	end
	
	def game_over(:internal, {:auto_complete, from}, %Room{hands: %Server{table: table}} = data) when length(table) < 5 do
		Server.deal_one
		update = %Room{ data | hands: Server.fetch_data}
		{:next_state, :game_over, update, [{:next_event, :internal, {:auto_complete, from}}]}
	end
	
	def game_over(:internal, {:auto_complete, from}, %Room{hands: %Server{table: table}} = data) when length(table) == 5 do
		Server.score
		update = %Room{ data | hands: Server.fetch_data}
		
		{:next_state, :game_over, update, [{:reply, from, :game_finished}, {:next_event, :internal, :reward_winner}]}
	end
	
	def game_over(event_type, event_content, data) do
		handle_event(event_type, event_content, data)
	end
	
	########## BETWEEN ROUNDS STATE ##############
	
	def between_rounds(:internal, :set_round, %Room{buffer: buffer} = data) do
	BetServer.clear
	Server.clear
	
		case length(Manager.fetch_data.seating) do
			x when x > 1 ->
				Manager.start_round
				buffer = Buffer.raise_pot(buffer, Manager.get_small_blind, @small_blind, 0)
				buffer = Buffer.raise_pot(buffer, Manager.get_big_blind, @big_blind, BetServer.get_to_call)
				update = 
					%Room{ data | buffer: buffer, table_state: Manager.fetch_data, hands: Server.deal_first_hand(Manager.players_only),
								 bet_history: BetServer.fetch_data
					}
				{:next_state, :pre_flop, update}
			_ -> 
				{:next_state, :idle, %Room{ data | table_state: Manager.fetch_data}}
		end
	end
	
	def between_rounds(event_type, event_content, data) do
		handle_event(event_type, event_content, data)
	end
	
	########## ALL STATE HANDLE EVENT CALLS ##############
	
	def handle_event({:call, from}, {:join, player}, %Room{buffer: buffer} = data) do
		Manager.seat_player(player)
		table_state = Manager.fetch_data
		
		case {length(table_state.seating), table_state.active} do
			{x, []} when x > 1 ->
				Manager.start_round
				Buffer.raise_pot(buffer, Manager.get_small_blind, @small_blind, 0)
				Buffer.raise_pot(buffer, Manager.get_big_blind, @big_blind, BetServer.get_to_call)
				update = 
					%Room{ data | table_state: Manager.fetch_data, hands: Server.deal_first_hand(Manager.players_only),
								 bet_history: BetServer.fetch_data
					}
				{:next_state, :pre_flop, update, [{:reply, from, update}]}
			_ ->
				update = %Room{ data | table_state: Manager.fetch_data}
				{:keep_state, update, [{:reply, from, update}]}
		end
	end
	
	def handle_event(:cast, :clear, data) do
		update = %Room{ data | table_state: %State{seating: data.table_state.seating}, bet_history: %History{}, hands: %Server{}}
		{:next_state, :idle, update}
	end
	
	def handle_event({:call, from}, :get_state, data) do
		{:keep_state, data, [{:reply, from, data}]}
	end
	
	def handle_event(:info, :setup, _data) do
		{:ok, bet_server} = BetServer.start_link
		{:ok, table_manager} = Manager.start_link([])
		{:ok, hand_server} = Server.start_link()
		{:next_state, :idle, %Room{bet_server: bet_server, table_manager: table_manager, hand_server: hand_server, buffer: %{called: []}}} 
	end
	
	def handle_event(:info, {:reward_winner, stats, paid, active, all_in}, data) do
		players = active ++ all_in |> Enum.map(fn {pl, seat} -> pl end)
		new_stats = Enum.filter(stats, fn {pl, _score} -> pl in players end) |> Enum.sort(fn {_, score1}, {_, score2} -> score1 > score2 end)
		{_, winning_score} = Enum.max_by(new_stats, fn {pl, score} -> score end)
		new_stats = Enum.filter(new_stats, fn {_pl, score} -> score == winning_score end)
		RewardManager.manage_rewards(new_stats, Map.to_list(paid)) |> RewardManager.distribute_rewards
		{:keep_state, data}
	end
	
	def handle_event(:info, {:reward_winner, [{winner, 100}], pot}, data) do
		Player.reward(winner, pot)
		{:keep_state, data}
	end
	
	def handle_event(event_type, event_content, data) do
		{:keep_state, data}
	end
	
	#####################
	# Utility functions #
	#####################
	
	defp update_room(data) do
		%Room{ data | table_state: Manager.fetch_data, bet_history: BetServer.fetch_data, hands: Server.fetch_data}
	end
	
	defp update_and_flop(data) do
		Manager.reset_turns
		Server.deal_flop
		BetServer.reset_round
		update_room(data)
	end
	
	defp update_and_deal(data) do
		Manager.reset_turns
		Server.deal_one
		BetServer.reset_round
		update_room(data)
	end
end