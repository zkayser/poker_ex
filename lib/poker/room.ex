defmodule PokerEx.Room do
	alias PokerEx.Game2
	alias PokerEx.BetServer
	alias PokerEx.BetHistory, as: History
	alias PokerEx.TableManager, as: Manager
	alias PokerEx.TableState, as: State
	alias PokerEx.HandServer, as: Server
	alias PokerEx.RewardManager
	alias PokerEx.Room, as: Room
	
	defstruct game: %{called: []}, table_state: %State{}, bet_history: %History{}, hands: %Server{},
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
	
	def idle({:call, from}, {:join, player}, %Room{game: game} = data) do
		Manager.seat_player(player)
		
		IO.puts "Seating: #{inspect(Manager.fetch_data.seating)}"
		case length(Manager.fetch_data.seating) do
			x when x > 1 ->
				Manager.start_round
				Game2.raise_pot(game, Manager.get_small_blind, @small_blind, 0)
				Game2.raise_pot(game, Manager.get_big_blind, @big_blind, BetServer.get_to_call)
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
	
	def pre_flop({:call, from}, {:call_pot, player}, %Room{game: %{called: called} = game} = data) do
		case length(Manager.get_active) - 1 > length(called) do
			true ->
				game = Game2.call(game, player)
				update = %Room{ data | game: game, bet_history: BetServer.fetch_data, table_manager: Manager.fetch_data}
				{:next_state, :pre_flop, update, [{:reply, from, update}]}
			_ ->
				game = Game2.call(game, player)
				updated_game = Game2.reset_called(game)
				Manager.reset_turns
				Server.deal_flop
				BetServer.reset_round
				update = %Room{ data | game: game, table_state: Manager.fetch_data, bet_history: BetServer.fetch_data, hands: Server.fetch_data}
				{:next_state, :flop, update, [{:reply, from, update}]}
		end
	end
	
	def pre_flop({:call, from}, {:raise_pot, player, amount}, %Room{game: game} = data) do
		case amount > BetServer.get_to_call do
			true ->
				game = Game2.raise_pot(game, player, amount, BetServer.get_to_call)
				update = %Room{ data | game: game, bet_history: BetServer.fetch_data, table_state: Manager.fetch_data}
				{:next_state, :pre_flop, update, [{:reply, from, update}]}
			_ ->
				{:next_state, :pre_flop, data, [{:reply, from, "#{player} tried to raise but did not cover #{BetServer.get_to_call}"}]}
		end
	end
	
	def pre_flop({:call, from}, {:check, player}, %Room{game: %{called: called} = game} = data) do
		case length(Manager.get_active) - 1 > length(called) do
			true ->
				game = Game2.check(game, player, BetServer.get_paid_in_round(player), BetServer.get_to_call)
				update = %Room{ data | game: game, bet_history: BetServer.fetch_data, table_state: Manager.fetch_data}
				{:next_state, :pre_flop, update, [{:reply, from, update}]}
			_ ->
				game = Game2.check(game, player, BetServer.get_paid_in_round(player), BetServer.get_to_call)
				Manager.reset_turns
				Server.deal_flop
				BetServer.reset_round
				update = %Room{ data | game: game, bet_history: BetServer.fetch_data, table_state: Manager.fetch_data, hands: Server.fetch_data}
				{:next_state, :flop, update, [{:reply, from, update}]}
		end
	end
	
	def pre_flop({:call, from}, {:fold, player}, %Room{game: game} = data) do
		case length(Manager.get_active) > 2 do
			true ->
				update = %Room{ data | table_state: Manager.fold(player)}
				{:next_state, :pre_flop, update, [{:reply, from, update}]}
			_ ->
				player = RewardManager.reward(player, BetServer.fetch_data.pot)
				update = %Room{ data | game: %{ game | winner: player}}
				{:next_state, :game_over, update, [{:reply, from, update}]}
		end
	end
	
	def pre_flop(event_type, event_content, data) do
		handle_event(event_type, event_content, data)
	end
	
	########## FLOP STATE #############
	
	def flop({:call, from}, {:call_pot, player}, %Room{game: %{called: called} = game} = data) do
		case length(Manager.get_active) - 1 > length(called) do
			true ->
				game = Game2.call(game, player)
				update = %Room{ data | game: game, bet_history: BetServer.fetch_data, table_manager: Manager.fetch_data}
				{:next_state, :flop, update, [{:reply, from, update}]}
			_ ->
				game = Game2.call(game, player)
				updated_game = Game2.reset_called(game)
				Manager.reset_turns
				Server.deal_one
				BetServer.reset_round
				update = %Room{ data | game: game, table_state: Manager.fetch_data, bet_history: BetServer.fetch_data, hands: Server.fetch_data}
				{:next_state, :turn, update, [{:reply, from, update}]}
		end
	end
	
	def flop({:call, from}, {:raise_pot, player, amount}, %Room{game: game} = data) do
		case amount > BetServer.get_to_call do
			true ->
				game = Game2.raise_pot(game, player, amount, BetServer.get_to_call)
				update = %Room{ data | game: game, bet_history: BetServer.fetch_data, table_state: Manager.fetch_data}
				{:next_state, :flop, update, [{:reply, from, update}]}
			_ ->
				{:next_state, :flop, data, [{:reply, from, "#{player} tried to raise but did not cover #{BetServer.get_to_call}"}]}
		end
	end
	
	def flop({:call, from}, {:check, player}, %Room{game: %{called: called} = game} = data) do
		case length(Manager.get_active) - 1 > length(called) do
			true ->
				game = Game2.check(game, player, BetServer.get_paid_in_round(player), BetServer.get_to_call)
				update = %Room{ data | game: game, bet_history: BetServer.fetch_data, table_state: Manager.fetch_data}
				{:next_state, :flop, update, [{:reply, from, update}]}
			_ ->
				game = Game2.check(game, player, BetServer.get_paid_in_round(player), BetServer.get_to_call)
				Manager.reset_turns
				Server.deal_one
				BetServer.reset_round
				update = %Room{ data | game: game, bet_history: BetServer.fetch_data, table_state: Manager.fetch_data, hands: Server.fetch_data}
				{:next_state, :turn, update, [{:reply, from, update}]}
		end
	end
	
	def flop({:call, from}, {:fold, player}, %Room{game: game} = data) do
		case length(Manager.get_active) > 2 do
			true ->
				update = %Room{ data | table_state: Manager.fold(player), bet_history: BetServer.fetch_data}
				{:next_state, :flop, update, [{:reply, from, update}]}
			_ ->
				player = RewardManager.reward(player, BetServer.fetch_data.pot)
				update = %Room{ data | game: %{ game | winner: player}}
				{:next_state, :game_over, update, [{:reply, from, update}]}
		end
	end
	
	def flop(event_type, event_content, data) do
		handle_event(event_type, event_content, data)
	end
	
	############ TURN STATE ##################
	
	def turn({:call, from}, {:call_pot, player}, %Room{game: %{called: called} = game} = data) do
		case length(Manager.get_active) - 1 > length(called) do
			true ->
				game = Game2.call(game, player)
				update = %Room{ data | game: game, bet_history: BetServer.fetch_data, table_manager: Manager.fetch_data}
				{:next_state, :turn, update, [{:reply, from, update}]}
			_ ->
				game = Game2.call(game, player)
				updated_game = Game2.reset_called(game)
				Manager.reset_turns
				Server.deal_one
				BetServer.reset_round
				update = %Room{ data | game: game, table_state: Manager.fetch_data, bet_history: BetServer.fetch_data, hands: Server.fetch_data}
				{:next_state, :river, update, [{:reply, from, update}]}
		end
	end
	
	def turn({:call, from}, {:raise_pot, player, amount}, %Room{game: game} = data) do
		case amount > BetServer.get_to_call do
			true ->
				game = Game2.raise_pot(game, player, amount, BetServer.get_to_call)
				update = %Room{ data | game: game, bet_history: BetServer.fetch_data, table_state: Manager.fetch_data}
				{:next_state, :turn, update, [{:reply, from, update}]}
			_ ->
				{:next_state, :turn, data, [{:reply, from, "#{player} tried to raise but did not cover #{BetServer.get_to_call}"}]}
		end
	end
	
	def turn({:call, from}, {:check, player}, %Room{game: %{called: called} = game} = data) do
		case length(Manager.get_active) - 1 > length(called) do
			true ->
				game = Game2.check(game, player, BetServer.get_paid_in_round(player), BetServer.get_to_call)
				update = %Room{ data | game: game, bet_history: BetServer.fetch_data, table_state: Manager.fetch_data}
				{:next_state, :turn, update, [{:reply, from, update}]}
			_ ->
				game = Game2.check(game, player, BetServer.get_paid_in_round(player), BetServer.get_to_call)
				Manager.reset_turns
				Server.deal_one
				BetServer.reset_round
				update = %Room{ data | game: game, bet_history: BetServer.fetch_data, table_state: Manager.fetch_data, hands: Server.fetch_data}
				{:next_state, :river, update, [{:reply, from, update}]}
		end
	end
	
	def turn({:call, from}, {:fold, player}, %Room{game: game} = data) do
		case length(Manager.get_active) > 2 do
			true ->
				update = %Room{ data | table_state: Manager.fold(player), bet_history: BetServer.fetch_data}
				{:next_state, :turn, update, [{:reply, from, update}]}
			_ ->
				player = RewardManager.reward(player, BetServer.fetch_data.pot)
				update = %Room{ data | game: %{ game | winner: player}}
				{:next_state, :game_over, update, [{:reply, from, update}]}
		end
	end
	
	def turn(event_type, event_content, data) do
		handle_event(event_type, event_content, data)
	end
	
	############### RIVER STATE ##############
	
	def river({:call, from}, {:call_pot, player}, %Room{game: %{called: called} = game} = data) do
		case length(Manager.get_active) - 1 > length(called) do
			true ->
				game = Game2.call(game, player)
				update = %Room{ data | game: game, bet_history: BetServer.fetch_data, table_manager: Manager.fetch_data}
				{:next_state, :river, update, [{:reply, from, update}]}
			_ ->
				game = Game2.call(game, player)
				updated_game = Game2.reset_called(game)
				Manager.reset_turns
				BetServer.reset_round
				update = %Room{ data | game: game, table_state: Manager.fetch_data, bet_history: BetServer.fetch_data, hands: Server.fetch_data}
				{:next_state, :game_over, update, [{:reply, from, update}]}
		end
	end
	
	def river({:call, from}, {:raise_pot, player, amount}, %Room{game: game} = data) do
		case amount > BetServer.get_to_call do
			true ->
				game = Game2.raise_pot(game, player, amount, BetServer.get_to_call)
				update = %Room{ data | game: game, bet_history: BetServer.fetch_data, table_state: Manager.fetch_data}
				{:next_state, :river, update, [{:reply, from, update}]}
			_ ->
				{:next_state, :river, data, [{:reply, from, "#{player} tried to raise but did not cover #{BetServer.get_to_call}"}]}
		end
	end
	
	def river({:call, from}, {:check, player}, %Room{game: %{called: called} = game} = data) do
		case length(Manager.get_active) - 1 > length(called) do
			true ->
				game = Game2.check(game, player, BetServer.get_paid_in_round(player), BetServer.get_to_call)
				update = %Room{ data | game: game, bet_history: BetServer.fetch_data, table_state: Manager.fetch_data}
				{:next_state, :river, update, [{:reply, from, update}]}
			_ ->
				game = Game2.check(game, player, BetServer.get_paid_in_round(player), BetServer.get_to_call)
				Manager.reset_turns
				BetServer.reset_round
				update = %Room{ data | game: game, bet_history: BetServer.fetch_data, table_state: Manager.fetch_data, hands: Server.fetch_data}
				{:next_state, :game_over, update, [{:reply, from, update}]}
		end
	end
	
	def river({:call, from}, {:fold, player}, %Room{game: game} = data) do
		case length(Manager.get_active) > 2 do
			true ->
				update = %Room{ data | table_state: Manager.fold(player), bet_history: BetServer.fetch_data}
				{:next_state, :river, update, [{:reply, from, update}]}
			_ ->
				player = RewardManager.reward(player, BetServer.fetch_data.pot)
				update = %Room{ data | game: %{ game | winner: player}}
				{:next_state, :game_over, update, [{:reply, from, update}]}
		end
	end
	
	def river(event_type, event_content, data) do
		handle_event(event_type, event_content, data)
	end
	
	########## ALL STATE HANDLE EVENT CALLS ##############
	
	def handle_event({:call, from}, {:join, player}, data) do
		update = %Room{ data | table_state: Manager.seat_player(player)}
		{:keep_state, update, [{:reply, from, update}]}
	end
	
	def handle_event(:cast, :clear, data) do
		update = %Room{ data | table_state: %State{seating: data.table_state.seating}, bet_history: %History{}, hands: %Server{}}
		{:next_state, :idle, update}
	end
	
	def handle_event({:call, from}, :get_state, data) do
		{:keep_state, data, [{:reply, from, data}]}
	end
	
	def handle_event(:info, :setup, data) do
		{:ok, bet_server} = BetServer.start_link
		{:ok, table_manager} = Manager.start_link([])
		{:ok, hand_server} = Server.start_link()
		{:next_state, :idle, %Room{bet_server: bet_server, table_manager: table_manager, hand_server: hand_server, game: %{called: []}}} 
	end
	
	def handle_event(event_type, event_content, data) do
		IO.puts "Received unknown event #{inspect(event_type)}, #{inspect(event_content)}"
		{:keep_state, data}
	end

end