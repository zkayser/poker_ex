defmodule PokerEx.Room do
	require Logger
	alias PokerEx.Room
	alias PokerEx.Player
	alias PokerEx.Events
	alias PokerEx.RewardManager
	alias PokerEx.Deck
	alias PokerEx.Hand
	alias PokerEx.Room.Updater
	alias PokerEx.Room.BetTracker
	alias PokerEx.Repo

	@big_blind 10
	@small_blind 5
	@timeout 30000
	@non_terminal_states [:pre_flop, :flop, :turn]
	@seating_capacity 7
	@minimum_buy_in 100

	@type chip_tracker :: %{(String.t | PokerEx.Player.t) => non_neg_integer} | %{}
	@type player_tracker :: [String.t | PokerEx.Player.t] | []
	@type seating :: [{String.t, non_neg_integer}] | []
	@type stats :: [{String.t, pos_integer}] | []
	@type chip_roll :: %{optional(String.t) => non_neg_integer} | %{}
	@type seat_number :: 0..6 | nil
	@type room_id :: atom()
	@type rewards :: [{String.t, pos_integer}] | []

	@type t :: %__MODULE__{
							to_call: non_neg_integer,
							paid: chip_tracker,
							round: chip_tracker,
							pot: non_neg_integer,
							called: [String.t],
							seating: seating,
							active: seating,
							skip_advance?: boolean(),
							type: atom(),
							chip_roll: chip_roll,
							current_big_blind: seat_number,
							current_small_blind: seat_number,
							all_in: player_tracker,
							folded: player_tracker,
							room_id: room_id,
							player_hands: [{String.t, [Card.t]}] | [],
							table: [Card.t] | [],
							deck: [Card.t] | [],
							stats: stats,
							rewards: rewards,
							winner: String.t | Player.t,
							winning_hand: Hand.t | nil,
							parent: pid,
							timeout: pos_integer
												}

	defstruct to_call: 0,
						paid: %{},
						round: %{},
						pot: 0,
						called: [],
						seating: [],
						active: [],
						skip_advance?: false,
						type: :public,
						chip_roll: %{},
						current_big_blind: nil,
						current_small_blind: nil,
						all_in: [],
						folded: [],
						room_id: nil,
						player_hands: [],
						table: [],
						deck: Deck.new |> Deck.shuffle,
						stats: [],
						rewards: [],
						winner: nil,
						winning_hand: nil,
						parent: nil,
						timeout: @timeout,
						timer: nil

	def start_link(args) when is_list(args) do
		id = List.first(args)
		:gen_statem.start_link({:local, id}, __MODULE__, [args], [])
	end

	def start_link(args) do
		room_id = :"#{args}"
		:gen_statem.start_link({:local, room_id}, __MODULE__, [args], [])
		# {:debug, [:trace, :log]}
	end

	def start_test(caller) do
		:gen_statem.start_link({:local, :test}, __MODULE__, [caller], [])
	end

	##############
	# Client API #
	##############

	def join(room_id, player, chip_amount) do
		:gen_statem.call(room_id, {:join, player.name, chip_amount})
	end

	def call(room_id, player) do
		:gen_statem.call(room_id, {:call, player.name})
	end

	def check(room_id, player) do
		:gen_statem.call(room_id, {:check, player.name})
	end

	def raise(room_id, player, amount) do
		:gen_statem.call(room_id, {:raise, player.name, amount})
	end

	def fold(room_id, player) do
		:gen_statem.call(room_id, {:fold, player.name})
	end

	def start(room_id) do
		:gen_statem.call(room_id, :start)
	end

	def leave(room_id, player) do
		:gen_statem.call(room_id, {:leave, player.name})
	end

	def player_count(room_id) do
		:gen_statem.call(room_id, :player_count)
	end

	def player_list(room_id) do
		:gen_statem.call(room_id, :player_list)
	end

	def state(room_id) do
		:gen_statem.call(room_id, :state)
	end

	def add_chips(room_id, player, amount) when amount > 0 do
		:gen_statem.call(room_id, {:add_chips, player, amount})
	end

	def put_state(room_id, new_state, new_data) do
		:gen_statem.call(room_id, {:put_state, new_state, new_data})
	end
	
	def start_new_round(room_id) do
		:gen_statem.call(room_id, :start_new_round)
	end
	
	def which_state(room_id) when is_binary(room_id) do
		:gen_statem.call(String.to_atom(room_id), :which_state)
	end

	def which_state(room_id) do
		:gen_statem.call(room_id, :which_state)
	end

	####################################
	# State Machine Callback Functions #
	####################################

	def terminate(:normal, _state, %Room{type: :public}), do: :void
	def terminate(_reason, _state, %Room{type: :public, chip_roll: chip_roll}) when is_map(chip_roll) do
		Logger.warn "Terminating public room and restoring chips to players."
		restore_chips_to_players(chip_roll)
		:void
	end
	def terminate(:manual, _state, %Room{chip_roll: chip_roll}) when is_map(chip_roll) do
		restore_chips_to_players(chip_roll)
		:void
	end
	def terminate(reason, state, %Room{type: :private, room_id: id} = room) do
		Logger.error "Now terminating #{inspect(id)} for reason: #{inspect reason}."
		Logger.error "Storing game state..."
		priv_room = PokerEx.Repo.get_by(PokerEx.PrivateRoom, title: Atom.to_string(id))
		room = :erlang.term_to_binary(room)
		state = :erlang.term_to_binary(state)
		data = %{"room_state" => state, "room_data" => room}
		PokerEx.PrivateRoom.store_state(priv_room, data)
		:void
	end

	def terminate(_reason, _state, _data) do
		:void
	end

	def code_change(_vsn, state, data, _extra) do
		{:ok, state, data}
	end

	def init([]), do: {:ok, :idle, %Room{}}
	def init([[id, :private]]) do
		Process.flag(:trap_exit, true)
		{:ok, :idle, %Room{type: :private, timeout: :infinity, room_id: id}}
	end
	def init([pid]) when is_pid(pid) do
		{:ok, :idle, %Room{parent: pid}}
	end
	def init([id]) do
		{:ok, :idle, %Room{room_id: id}}
	end

	def callback_mode do
		[:handle_event_function, :state_enter]
	end

	###################
	# State Functions #
	###################

	###############
	#  Idle State #
	###############
	
	def handle_event({:call, from}, {:join, player, chip_amount}, :idle, %Room{seating: seating} = room)
	when length(seating) < 1 and chip_amount >= @minimum_buy_in do
		case player_can_join?(player, seating) do
			true ->
				{:ok, _} = Player.subtract_chips(player, chip_amount)
				update =
					room
					|> Updater.seating(player)
					|> Updater.chip_roll(player, chip_amount)
				{:next_state, :idle, update, [{:reply, from, update}]}
			false ->
				{:keep_state_and_data, [{:reply, from, room}]}
		end
	end

	def handle_event({:call, from}, {:join, player, chip_amount}, :idle, %Room{seating: seating} = room)
	when length(seating) >= 1 and chip_amount >= @minimum_buy_in do
		case player_can_join?(player, seating) do
			true ->
				{:ok, _} = Player.subtract_chips(player, chip_amount)
				update =
					room
					|> Updater.seating(player)
					|> Updater.chip_roll(player, chip_amount)
					|> Updater.blinds
					|> Updater.set_active
					|> Updater.player_hands
					|> Updater.timer(@timeout)
					|> BetTracker.post_blind(@small_blind, :small_blind)
					|> BetTracker.post_blind(@big_blind, :big_blind)
					
				{:next_state, :pre_flop, update, [{:reply, from, update}]}
		false ->
			{:keep_state_and_data, [{:reply, from, room}]}
		end
	end

	########################
	# Between Rounds State #
	########################

	def handle_event({:call, from}, {:join, player, chip_amount}, :between_rounds, %Room{seating: seating} = room)
	when length(seating) == 1 and chip_amount >= @minimum_buy_in do
		case player_can_join?(player, seating) do
			true ->
				{:ok, _} = Player.subtract_chips(player, chip_amount)
				update =
					room
					|> round_transition(:between_rounds)
					|> Updater.reset_total_paid
					|> Updater.reset_table
					|> Updater.reset_folded
					|> Updater.reset_player_hands
					|> Updater.reset_deck
					|> Updater.reset_stats
					|> Updater.reset_rewards
					|> Updater.reset_winner
					|> Updater.reset_winning_hand
					|> Updater.reset_pot
					|> Updater.reset_all_in
					|> Updater.seating(player)
					|> Updater.chip_roll(player, chip_amount)
					|> Updater.blinds
					|> Updater.set_active
					|> Updater.player_hands
					|> Updater.timer(@timeout)
					|> BetTracker.post_blind(@small_blind, :small_blind)
					|> BetTracker.post_blind(@big_blind, :big_blind)
		
				{:next_state, :pre_flop, update, [{:reply, from, update}]}
		false ->
			{:keep_state_and_data, [{:reply, from, room}]}
		end
	end

	####################################
	# Player join callbacks, any state #
	####################################

	def handle_event({:call, from}, {:join, player, chip_amount}, state, %Room{seating: seating} = room) when length(seating) <= @seating_capacity do
		case player_can_join?(player, seating) do
			true ->
				{:ok, _} = Player.subtract_chips(player, chip_amount)
				update =
					room
					|> Updater.seating(player)
					|> Updater.chip_roll(player, chip_amount)
				{:next_state, state, update, [{:reply, from, update}]}
			false ->
				{:keep_state_and_data, [{:reply, from, room}]}
		end
	end

	def handle_event({:call, from}, {:join, _player}, state, room), do: {:next_state, state, room, [{:reply, from, room}]}

	#####################################
	# Player leave callbacks, any state #
	#####################################

	def handle_event({:call, from}, {:leave, player}, _state, %Room{seating: seating, active: active} = room)
	when length(seating) == 1 and length(active) <= 1 do
		update =
			room
			|> Updater.chip_roll(player, :leaving)
			|> Updater.reset_table_state
			|> Updater.remove_from_seating(player)
			|> Updater.reindex_seating
		{:next_state, :idle, update, [{:reply, from, update}]}
	end

	def handle_event({:call, from}, {:leave, player}, state, %Room{active: active} = room)
	when length(active) == 2 and state in [:pre_flop, :flop, :turn, :river] do
		active_players = Enum.map(active, fn {player, _} -> player end)
		unless player in active_players do
			update =
				room
				|> Updater.chip_roll(player, :leaving)
				|> Updater.remove_from_seating(player)
				|> Updater.reindex_seating
			{:next_state, state, update, [{:reply, from, update}]}
		else
			update =
				room
				|> Updater.chip_roll(player, :leaving)
				|> Updater.remove_from_seating(player)
				|> Updater.maybe_advance_active(player)
				|> Updater.active(player)
				|> Updater.reindex_seating
			{:next_state, :game_over, update, [{:reply, from, update}, {:next_event, :internal, :handle_fold}]}
		end
	end

	def handle_event({:call, from}, {:leave, player}, state, %Room{seating: seating} = room)
	when length(seating) == 2 and state in [:pre_flop, :flop, :turn, :river] do
		update =
			room
			|> Updater.chip_roll(player, :leaving)
			|> Updater.remove_from_seating(player)
			|> Updater.maybe_advance_active(player)
			|> Updater.active(player)
			|> Updater.reindex_seating
		{:next_state, :game_over, update, [{:reply, from, update}, {:next_event, :internal, :handle_fold}]}
	end

	def handle_event({:call, from}, {:leave, player}, _state, %Room{seating: seating} = room) when length(seating) == 2 do
		update =
			room
			|> Updater.chip_roll(player, :leaving)
			|> Updater.clear_room
			|> Updater.remove_from_seating(player)
			|> Updater.reindex_seating

		Events.clear_ui(room.room_id)
		{:next_state, :idle, update, [{:reply, from, update}]}
	end

	def handle_event({:call, from}, {:leave, player}, state, %Room{seating: seating, active: active} = room)
	when seating > 2 and state in [:pre_flop, :flop, :turn, :river] do
		reducer = fn {pl, _} -> pl end
		active_players = Enum.map(active, reducer)
		update =
			case player in active_players do
				true ->
					room
					|> Updater.chip_roll(player, :leaving)
					|> Updater.remove_from_seating(player)
					|> Updater.reindex_seating
					|> Updater.maybe_advance_active(player)
					|> Updater.remove_from_active(player)
				false ->
					room
					|> Updater.chip_roll(player, :leaving)
					|> Updater.remove_from_seating(player)
					|> Updater.reindex_seating
			end

		case update.active == 1 do
			true -> {:next_state, :game_over, update, [{:reply, from, update}, {:next_event, :internal, :handle_fold}]}
			_ -> {:next_state, state, update, [{:reply, from, update}]}
		end
	end

	def handle_event({:call, from}, {:leave, player}, state, %Room{seating: seating} = room) do
		seated_players = Enum.map(seating, fn {pl, _num} -> pl end)
		update =
			case player in seated_players do
				true ->
					room
					|> Updater.chip_roll(player, :leaving)
					|> Updater.remove_from_seating(player)
					|> Updater.reindex_seating
					|> Updater.advance_active
					|> Updater.remove_from_active(player)
				_ -> room
			end
		{:next_state, state, update, [{:reply, from, update}]}
	end

	##########################################
	# Callbacks for (Poker) calls, any state #
	##########################################

	def handle_event({:call, from}, {:call, player}, state, %Room{called: called, active: active} = room)
	when length(called) < length(active) - 1 do
		update =
			room
			|> BetTracker.call(player)
		{:next_state, state, update, [{:reply, from, update}]}
	end

	def handle_event({:call, from}, {:call, player}, state, %Room{all_in: all_in, folded: folded, seating: seating} = room)
	when length(all_in) + length(folded) == length(seating) - 1 and state in @non_terminal_states do
		update =
			room
			|> Updater.no_advance_event
			|> BetTracker.call(player)
			|> round_transition(state)
		{:next_state, :game_over, update, [{:reply, from, :skip_update_message}, {:next_event, :internal, :handle_all_in}]}
	end

	def handle_event({:call, from}, {:call, player}, state, room) when state in @non_terminal_states do
		update =
			room
			|> Updater.no_advance_event
			|> BetTracker.call(player)
			|> round_transition(state)

		{all_in, folded, seating} = {update.all_in, update.folded, update.seating}
		case (length(all_in) + length(folded) == length(seating) - 1) do
			true ->
				{:next_state, :game_over, update, [{:reply, from, :skip_update_message}, {:next_event, :internal, :handle_all_in}]}
			_ ->
				{:next_state, advance_state(state), update, [{:reply, from, update}]}
		end
	end

	def handle_event({:call, from}, {:call, player}, :river, room) do
		update =
			room
			|> BetTracker.call(player)
		{:next_state, :game_over, update, [{:reply, from, :skip_update_message}, {:next_event, :internal, :reward_winner}]}
	end

	#########################################
	# Callbacks for fold actions, any state #
	#########################################

	def handle_event({:call, from}, {:fold, player}, state, %Room{active: active, all_in: all_in} = room)
	when length(active) == 2 or length(all_in) >= 1 and length(active) == 1 do
		update =
			room
			|> BetTracker.fold(player)
			|> round_transition(state)
		{:next_state, :game_over, update, [{:reply, from, :skip_update_message}, {:next_event, :internal, :handle_fold}]}
	end

	def handle_event({:call, from}, {:fold, player}, state, %Room{called: called, active: active} = room) when length(called) >= length(active) - 1 do
		update =
			room
			|> BetTracker.fold(player)
			|> round_transition(state)
		{:next_state, advance_state(state), update, [{:reply, from, update}]}
	end

	def handle_event({:call, from}, {:fold, player}, state, room) do
		update =
			room
			|> BetTracker.fold(player)
		{:next_state, state, update, [{:reply, from, update}]}
	end

	##########################################
	# Callbacks for check actions, any state #
	##########################################

	def handle_event({:call, from}, {:check, player}, state, %Room{to_call: call_amount, round: round, called: called, active: active} = room)
	when length(called) < length(active) - 1 do
		update =
			case call_amount == round[player] || call_amount == 0 do
				true ->
					room
					|> BetTracker.check(player)
				_ ->
					room
			end
		{:next_state, state, update, [{:reply, from, update}]}
	end

	def handle_event({:call, from}, {:check, player}, state, %Room{to_call: call_amount, round: round, all_in: all_in, active: active} = room)
	when length(all_in) >= 1 and length(active) == 1 do
		update =
			case call_amount == round[player] || call_amount == 0 do
				true ->
					room
					|> Updater.no_advance_event
					|> BetTracker.check(player)
					|> round_transition(state)
				_ ->
					room
			end
		{:next_state, :game_over, update, [{:reply, from, :skip_update_message}, {:next_event, :internal, :handle_all_in}]}
	end

	def handle_event({:call, from}, {:check, player}, state, %Room{to_call: call_amount, round: round, called: called, active: active} = room)
	when length(called) >= length(active) - 1 and state in @non_terminal_states do
		update =
			case call_amount == round[player] || call_amount == 0 do
				true ->
					room
					|> Updater.no_advance_event
					|> BetTracker.check(player)
					|> round_transition(state)
				_ ->
					room
			end
		{:next_state, advance_state(state), update, [{:reply, from, update}]}
	end

	def handle_event({:call, from}, {:check, player}, :river, %Room{to_call: call_amount, round: round, called: called, active: active} = room)
	when length(called) >= length(active) - 1 do
		update =
			case call_amount == round[player] || call_amount == 0 do
				true ->
					room
					|> BetTracker.check(player)
				_ ->
					room
			end
		{:next_state, :game_over, update, [{:reply, from, :skip_update_message}, {:next_event, :internal, :reward_winner}]}
	end

	##################
	# Raise callback #
	##################

	def handle_event({:call, from}, {:raise, player, amount}, state, %Room{to_call: call_amount} = room) when amount > call_amount do
		update =
			room
			|> BetTracker.raise(player, amount)
		{:next_state, state, update, [{:reply, from, update}]}
	end

	#################################
	# Callbacks for internal events #
	#################################

	def handle_event(:internal, :reward_winner, :game_over, %Room{winner: nil} = room) do
		update =
			room
			|> Updater.stats
			|> Updater.winner
			|> RewardManager.manage_rewards
			|> RewardManager.distribute_rewards

		Events.present_winning_hand(room.room_id, update.winning_hand.best_hand, update.winner, update.winning_hand.type_string)
		{:next_state, :between_rounds, update, [{:next_event, :internal, :set_round}]}
	end

	def handle_event(:internal, :handle_fold, :game_over, %Room{all_in: all_in, active: active} = room)
	when length(all_in) == 0 and length(active) == 1 do
		{winner, _} = hd(active)
		update =
			room
			|> Updater.insert_winner(winner)
			|> Updater.insert_stats(winner, 100)
			|> RewardManager.manage_rewards
			|> RewardManager.distribute_rewards

		Events.winner_message(room.room_id, "#{update.winner} wins the round on a fold")
		{:next_state, :between_rounds, update, [{:next_event, :internal, :set_round}]}
	end

	def handle_event(:internal, :handle_fold, :game_over, %Room{all_in: all_in, active: active} = room)
	when length(all_in) == 1 and length(active) == 0 do
		winner = hd(all_in)
		update =
			room
			|> Updater.insert_winner(winner)
			|> Updater.insert_stats(winner, 100)
			|> RewardManager.manage_rewards
			|> RewardManager.distribute_rewards

		Events.winner_message(room.room_id, "#{update.winner} wins the round on a fold")
		{:next_state, :between_rounds, update, [{:next_event, :internal, :set_round}]}
	end

	def handle_event(:internal, :handle_fold, :game_over, %Room{all_in: all_in, table: table} = room)
	when length(all_in) >= 1 and length(table) < 5 do
		update =
			room
			|> Updater.table
		{:next_state, :game_over, update, [{:next_event, :internal, :handle_fold}]}
	end

	def handle_event(:internal, :handle_fold, :game_over, %Room{all_in: all_in, table: table} = room)
	when length(all_in) >= 1 and length(table) == 5 do
		update =
			room
			|> Updater.stats
			|> Updater.winner
			|> RewardManager.manage_rewards
			|> RewardManager.distribute_rewards

		Events.present_winning_hand(room.room_id, update.winning_hand.best_hand, update.winner, update.winning_hand.type_string)
		{:next_state, :between_rounds, update, [{:next_event, :internal, :set_round}]}
	end

	def handle_event(:internal, :handle_all_in, :game_over, %Room{table: table} = room) when length(table) < 5 do
		update =
			room
			|> Updater.table
		{:next_state, :game_over, update, [{:next_event, :internal, :handle_all_in}]}
	end

	def handle_event(:internal, :handle_all_in, :game_over, %Room{table: table} = room) when length(table) == 5 do
		update =
			room
			|> Updater.stats
			|> Updater.winner
			|> RewardManager.manage_rewards
			|> RewardManager.distribute_rewards

		Events.present_winning_hand(room.room_id, update.winning_hand.best_hand, update.winner, update.winning_hand.type_string)
		{:next_state, :between_rounds, update, [{:next_event, :internal, :set_round}]}
	end

	def handle_event(:internal, :set_round, :between_rounds, %Room{seating: seating} = room) when length(seating) > 1 do
		update_one =
			room
			|> round_transition(:between_rounds)
			|> Updater.remove_players_with_no_chips
		case length(update_one.seating) > 1 do
			true ->
				update =
					update_one
					|> Updater.blinds
					|> Updater.set_active
					|> Updater.reset_table
					|> Updater.reset_folded
					|> Updater.reset_total_paid
					|> Updater.reset_player_hands
					|> Updater.reset_deck
					|> Updater.reset_stats
					|> Updater.reset_rewards
					|> Updater.reset_winner
					|> Updater.reset_winning_hand
					|> Updater.reset_pot
					|> Updater.reset_all_in
					|> Updater.player_hands
					|> BetTracker.post_blind(@small_blind, :small_blind)
					|> BetTracker.post_blind(@big_blind, :big_blind)

				{:next_state, :pre_flop, update}
			_ ->
				{:next_state, :between_rounds, update_one, [{:next_event, :internal, :clear}]}
		end
	end

	def handle_event(:internal, :clear, :between_rounds, room) do
		update =
			room
			|> Updater.reset_table
			|> Updater.reset_total_paid
			|> Updater.reset_player_hands
			|> Updater.reset_deck
			|> Updater.reset_stats
			|> Updater.reset_rewards
			|> Updater.reset_winner
			|> Updater.reset_winning_hand
			|> Updater.reset_pot
			|> Updater.reset_all_in
		IO.puts "\nEntering idle state"
		{:next_state, :idle, update}
	end

	def handle_event(:internal, :set_round, :between_rounds, room) do
		update = reset_all(room)
		{:next_state, :between_rounds, update}
	end

	############################
	# Player timeout callbacks #
	############################

	def handle_event(:info, {:timeout, _tref, :auto_fold}, state, %Room{active: active} = room)
	when state in [:pre_flop, :flop, :turn, :river] and length(active) > 1 do
		{current_player, _} = hd(active)
		update =
			room
			|> BetTracker.fold(current_player)
		case update.active do
			x when length(x) > 1 ->
				Events.state_updated(room.room_id, update)
				{:next_state, state, update}
			_ ->
				{:next_state, :game_over, update, [{:next_event, :internal, :handle_fold}]}
		end
	end

	def handle_event(:info, {:timeout, _tref, :auto_fold}, state, room) do
		update =
			room
			|> Updater.clear_timer
		{:next_state, state, update}
	end

	####################################
	# Callbacks for debugging purposes #
	####################################

	def handle_event({:call, from}, :player_count, state, %Room{seating: seating} = room) do
		{:next_state, state, room, [{:reply, from, length(seating)}]}
	end

	def handle_event({:call, from}, :player_list, state, %Room{seating: seating} = room) do
		players = Enum.map(seating, fn {player, _} -> Repo.get_by(Player, name: player) end)
		{:next_state, state, room, [{:reply, from, players}]}
	end

	def handle_event({:call, from}, :which_state, state, room) do
		{:next_state, state, room, [{:reply, from, state}]}
	end

	def handle_event({:call, from}, {:add_chips, player, amount}, state, room) do
		update =
			room
			|> Updater.chip_roll(player, {:adding, amount})
		{:next_state, state, update, [{:reply, from, update}]}
	end

	def handle_event({:call, from}, {:put_state, new_state, new_data}, _state, _room) do
		{:next_state, new_state, new_data, [{:reply, from, new_data}]}
	end
	
	def handle_event({:call, from}, :start_new_round, _state, room) do
		new_round(room, from)
	end

	# DEBUGGING
	def handle_event({:call, from}, :state, state, room) do
		{:next_state, state, room, [{:reply, from, room}]}
	end
	
	# State enter callback
	def handle_event(:enter, _old_state, :pre_flop, room) do
		Events.game_started(room.room_id, room)
		{:next_state, :pre_flop, room}
	end
	
	def handle_event(:enter, _, state, room), do: {:next_state, state, room}

	# CATCH ALL CALLBACK
	def handle_event(event_type, event_content, state, data) do
		Logger.warn "Unknown event: #{inspect(event_type)} with content: #{inspect(event_content)} in state: #{inspect(state)}"
		{:next_state, state, data}
	end

	#####################
  # Utility Functions #
  #####################

  defp advance_state(:pre_flop), do: :flop
  defp advance_state(:flop), do: :turn
  defp advance_state(:turn), do: :river
  defp advance_state(:river), do: :game_over
  defp advance_state(:game_over), do: :between_rounds
  defp advance_state(:between_rounds), do: :pre_flop

  defp round_transition(room, :pre_flop) do
  		room
  		|> transition
  		|> Updater.table
  		|> Updater.table
  		|> Updater.table
  end

  defp round_transition(room, :between_rounds) do
  		room
  		|> transition
  end

  defp round_transition(room, _state) do
  		room
  		|> transition
  		|> Updater.table
  end

  defp transition(room) do
  	room
  	|> Updater.reset_advance_event_flag
  	|> Updater.reset_active
  	|> Updater.reset_paid_in_round
  	|> Updater.reset_call_amount
  	|> Updater.reset_called
  	|> Updater.timer(@timeout)
  end
  
  defp player_can_join?(player, seating) do
  	player not in Enum.map(seating, fn {name, _pos} -> name end)
  end

  defp restore_chips_to_players(chip_roll) do
  	chip_roll
			|> Map.keys
			|> Enum.each(fn p -> Player.update_chips(p, chip_roll[p]) end)
  end
  
  defp reset_all(room) do
			room
			|> round_transition(:between_rounds)
			|> Updater.reset_table_state
			|> Updater.remove_players_with_no_chips
			|> Updater.reset_total_paid
			|> Updater.reset_table
			|> Updater.reset_folded
			|> Updater.reset_player_hands
			|> Updater.reset_deck
			|> Updater.reset_stats
			|> Updater.reset_rewards
			|> Updater.reset_winner
			|> Updater.reset_winning_hand
			|> Updater.reset_pot
			|> Updater.reset_all_in
  end
  
  defp new_round(room, from_pid) do
  		update =
				room
				|> round_transition(:between_rounds)
				|> Updater.reset_total_paid
				|> Updater.reset_table
				|> Updater.reset_folded
				|> Updater.reset_player_hands
				|> Updater.reset_deck
				|> Updater.reset_stats
				|> Updater.reset_rewards
				|> Updater.reset_winner
				|> Updater.reset_winning_hand
				|> Updater.reset_pot
				|> Updater.reset_all_in
				|> Updater.blinds
				|> Updater.set_active
				|> Updater.player_hands
				|> Updater.timer(@timeout)
				|> BetTracker.post_blind(@small_blind, :small_blind)
				|> BetTracker.post_blind(@big_blind, :big_blind)

		{:next_state, :pre_flop, update, [{:reply, from_pid, update}]}
  end
end
