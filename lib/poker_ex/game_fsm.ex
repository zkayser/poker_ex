defmodule PokerEx.GameFSM do
	alias PokerEx.Game
	alias PokerEx.Player
	alias PokerEx.AppState
	alias PokerEx.Deck
	alias PokerEx.TableManager, as: Manager
	
	@name :game_fsm
	
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
		{:ok, :idle, Game.new}
	end
	
	def callback_mode do
		:state_functions
	end
	
	###################
	# State Functions #
	###################
	
	def idle({:call, from}, {:join, player}, %Game{sitting: sitting, players: players, deck: deck, current_paid: cp} = data) when length(sitting) >= 1 do
		Manager.start_link([player|sitting])
		new_data = %Game{ data | sitting: [player|sitting], players: [player|players], current_paid: [{0, player}|cp], state: Manager.start_round}
		game = Game.start(new_data)
		{:next_state, :pre_flop, game, [{:reply, from, game}]}
	end
	
	def idle({:call, from}, {:join, player}, %Game{sitting: sitting, players: players, current_paid: cp} = data) do
		game = %Game{ data | sitting: [player|sitting], players: [player|players], current_paid: [{0, player}|cp]}
		{:next_state, :idle, game, [{:reply, from, game}]}
	end
	
	def idle(event_type, event_content, data) do
		handle_event(event_type, event_content, data)
	end
	
	########## PRE_FLOP #############
	
	def pre_flop({:call, from}, {:call_pot, player}, %Game{players: players, called: called} = game) when (length(players) - 1) > length(called) do
		update = Game.call_pot(game, player)
		{:next_state, :pre_flop, update, [{:reply, from, update}]}
	end
	
	def pre_flop({:call, from}, {:call_pot, player}, game) do
		update = Game.call_pot(game, player) |> Game.reset_current_paid |> Game.reset_to_call |> Game.deal_flop
		{:next_state, :flop, update, [{:reply, from, update}]}
	end
	
	def pre_flop({:call, from}, {:check, player}, %Game{players: players, called: called} = game) when (length(players) - 1) > length(called) do
		update = Game.check(game, player)
		{:next_state, :pre_flop, update, [{:reply, from, update}]}
	end
	
	def pre_flop({:call, from}, {:check, player}, game) do
		update = Game.check(game, player) |> Game.reset_current_paid |> Game.reset_to_call |> Game.deal_flop
		{:next_state, :flop, update, [{:reply, from, update}]}
	end
	
	def pre_flop({:call, from}, {:raise_pot, player, amount}, game) do
		update = Game.raise_pot(game, player, amount)
		{:next_state, :pre_flop, update, [{:reply, from, update}]}
	end
	
	def pre_flop({:call, from}, {:fold, player}, %Game{players: players} = game) when length(players) > 2 do
		update = Game.fold(game, player)
		{:next_state, :pre_flop, update, [{:reply, from, update}]}
	end
	
	def pre_flop({:call, from}, {:fold, player}, game) do
		update = Game.fold(game, player)
		{:next_state, :game_over, update, [{:reply, from, update}, {:next_event, :internal, :reward_winner}]}
	end
	
	def pre_flop(event_type, event_content, data) do
		handle_event(event_type, event_content, data)
	end
	
	###### FLOP #########
	
	def flop({:call, from}, {:call_pot, player}, %Game{players: players, called: called} = game) when (length(players) - 1) > length(called) do
		update = Game.call_pot(game, player)
		{:next_state, :flop, update, [{:reply, from, update}]}
	end
	
	def flop({:call, from}, {:call_pot, player}, game) do
		update = Game.call_pot(game, player) |> Game.reset_current_paid |> Game.reset_to_call |> Game.deal_one
		{:next_state, :turn, update, [{:reply, from, update}]}
	end
	
	def flop({:call, from}, {:check, player}, %Game{players: players, called: called} = game) when (length(players) - 1) > length(called) do
		update = Game.check(game, player)
		{:next_state, :flop, update, [{:reply, from, update}]}
	end
	
	def flop({:call, from}, {:check, player}, game) do
		update = Game.check(game, player) |> Game.reset_current_paid |> Game.reset_to_call |> Game.deal_one
		{:next_state, :turn, update, [{:reply, from, update}]}
	end
	
	def flop({:call, from}, {:raise_pot, player, amount}, game) do
		update = Game.raise_pot(game, player, amount)
		{:next_state, :flop, update, [{:reply, from, update}]}
	end
	
	def flop({:call, from}, {:fold, player}, %Game{players: players} = game) when length(players) > 2 do
		update = Game.fold(game, player)
		{:next_state, :flop, update, [{:reply, from, update}]}
	end
	
	def flop({:call, from}, {:fold, player}, game) do
		update = Game.fold(game, player)
		{:next_state, :game_over, update, [{:reply, from, update}, {:next_event, :internal, :reward_winner}]}
	end
	
	def flop(event_type, event_content, data) do
		handle_event(event_type, event_content, data)
	end
	
	######### Turn #################
	
	def turn({:call, from}, {:call_pot, player}, %Game{players: players, called: called} = game) when (length(players) - 1) > length(called) do
		update = Game.call_pot(game, player)
		{:next_state, :turn, update, [{:reply, from, update}]}
	end
	
	def turn({:call, from}, {:call_pot, player}, game) do
		update = Game.call_pot(game, player) |> Game.reset_current_paid |> Game.reset_to_call |> Game.deal_one
		{:next_state, :river, update, [{:reply, from, update}]}
	end
	
	def turn({:call, from}, {:check, player}, %Game{players: players, called: called} = game) when (length(players) - 1) > length(called) do
		update = Game.check(game, player)
		{:next_state, :turn, update, [{:reply, from, update}]}
	end
	
	def turn({:call, from}, {:check, player}, game) do
		update = Game.check(game, player) |> Game.reset_current_paid |> Game.reset_to_call |> Game.deal_one
		{:next_state, :river, update, [{:reply, from, update}]}
	end
	
	def turn({:call, from}, {:raise_pot, player, amount}, game) do
		update = Game.raise_pot(game, player, amount)
		{:next_state, :turn, update, [{:reply, from, update}]}
	end
	
	def turn({:call, from}, {:fold, player}, %Game{players: players} = game) when length(players) > 2 do
		update = Game.fold(game, player)
		{:next_state, :turn, update, [{:reply, from, update}]}
	end
	
	def turn({:call, from}, {:fold, player}, game) do
		update = Game.fold(game, player)
		{:next_state, :game_over, update, [{:reply, from, update}, {:next_event, :internal, :reward_winner}]}
	end
	
	def turn(event_type, event_content, data) do
		handle_event(event_type, event_content, data)
	end
	
	########### RIVER #################
	
	def river({:call, from}, {:call_pot, player}, %Game{players: players, called: called} = game) when (length(players) - 1) > length(called) do
		update = Game.call_pot(game, player)
		{:next_state, :river, update, [{:reply, from, update}]}
	end
	
	def river({:call, from}, {:call_pot, player}, game) do
		update = Game.call_pot(game, player) |> Game.determine_winner
		{:next_state, :game_over, update, [{:reply, from, update}, {:next_event, :internal, :reward_winner}]}
	end
	
	def river({:call, from}, {:check, player}, %Game{players: players, called: called} = game) when (length(players) - 1) > length(called) do
		update = Game.check(game, player)
		{:next_state, :river, update, [{:reply, from, update}]}
	end
	
	def river({:call, from}, {:check, player}, game) do
		update = Game.check(game, player) |> Game.determine_winner
		{:next_state, :game_over, update, [{:reply, from, update}, {:next_event, :internal, :reward_winner}]}
	end
	
	def river({:call, from}, {:raise_pot, player, amount}, game) do
		update = Game.raise_pot(game, player, amount)
		{:next_state, :river, update, [{:reply, from, update}]}
	end
	
	def river({:call, from}, {:fold, player}, %Game{players: players} = game) when length(players) > 2 do
		update = Game.fold(game, player)
		{:next_state, :river, update, [{:reply, from, update}]}
	end
	
	def river({:call, from}, {:fold, player}, game) do
		update = Game.fold(game, player)
		{:next_state, :game_over, update, [{:reply, from, update}, {:next_event, :internal, :reward_winner}]}
	end
	
	def river(event_type, event_content, data) do
		handle_event(event_type, event_content, data)
	end
	
	########### Game Over ##############
	
	def game_over(event_type, event_content, data) do
		handle_event(event_type, event_content, data)
	end
	
	############ Between Games ##########
	
	def between_games({:call, from}, {:ready, player}, %Game{sitting: sitting, ready: ready, current_paid: cp} = data) when (length(sitting) - 1) > length(ready) do
		update = %Game{ data | ready: [player|ready], current_paid: [{0, player}|cp]}
		{:next_state, :between_games, update, [{:reply, from, :update}]}
	end
	
	def between_games({:call, from}, {:ready, player}, %Game{sitting: sitting, ready: ready, current_paid: cp} = data) do
		update = %Game{ data | ready: [], players: [player|ready], current_paid: [{0, player}|cp]} |> Game.deal_first_hand
		{:next_state, :pre_flop, update, [{:reply, from, :update}]}
	end
	
	def between_games(event_type, event_content, data) do
		handle_event(event_type, event_content, data)
	end
	
	######################
	# Handle Event Calls #
	######################
	
	def handle_event({:call, from}, :get_state, data) do
		{:keep_state, data, [{:reply, from, data}]}
	end
	
	def handle_event({:call, from}, {:join, player}, %Game{sitting: sitting} = data) do
		update = %Game{ data | sitting: [player|sitting] }
		{:keep_state, update, [{:reply, from, update}]}
	end
	
	def handle_event({:call, from}, {:leave, player}, %Game{sitting: sitting} = game) do
		update = %Game{ game | sitting: sitting -- player} |> Game.fold(player)
		{:keep_state, update, [{:reply, from, update}]}
	end
	
	def handle_event(:timeout, %Game{}, %Game{deck: deck} = game) when is_nil(deck) do
		update = Game.start(game)
		{:next_state, :pre_flop, update}
	end
	
	def handle_event(:internal, :reward_winner, %Game{sitting: sitting} = game) do
		Game.reward_winner(game)
		new_game = Game.new
		new_game = %Game{ new_game | sitting: sitting }
		{:next_state, :between_games, new_game}
	end
	
	def handle_event(:cast, :clear, _game) do
		{:next_state, :idle, Game.new}
	end
	
	def handle_event(event_type, event_content, data) do
		IO.puts "\nReceived unknown message: \n"
		IO.inspect(event_type)
		IO.inspect(event_content)
		IO.inspect(data)
		IO.puts "\n"
	end
	
	#####################
	# Utility Functions #
	#####################
	
end