defmodule PokerEx.Room do
	alias PokerEx.Room, as: Room
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
	
	@type chip_tracker :: %{(String.t | PokerEx.Player.t) => non_neg_integer} | %{}
	@type player_tracker :: [String.t | PokerEx.Player.t] | []
	@type seating :: [{String.t, non_neg_integer}] | []
	@type stats :: [{String.t, pos_integer}] | []
	@type seat_number :: 0..6 | nil
	@type room_id :: atom()
	
	@type t :: %__MODULE__{
							to_call: non_neg_integer,
							paid: chip_tracker,
							round: chip_tracker,
							pot: non_neg_integer,
							called: [String.t],
							seating: seating,
							active: seating,
							current_big_blind: seat_number,
							current_small_blind: seat_number,
							all_in: player_tracker,
							folded: player_tracker,
							room_id: room_id,
							player_hands: [{String.t, [Card.t]}] | [],
							table: [Card.t] | [],
							deck: [Card.t] | [],
							stats: stats,
							winner: String.t | Player.t,
							winning_hand: Hand.t | nil
												}
	
	defstruct to_call: 0,
						paid: %{},
						round: %{},
						pot: 0,
						called: [],
						seating: [],
						active: [],
						current_big_blind: nil,
						current_small_blind: nil,
						all_in: [],
						folded: [],
						room_id: nil,
						player_hands: [],
						table: [],
						deck: Deck.new |> Deck.shuffle,
						stats: [],
						winner: nil,
						winning_hand: nil
						
	def start_link(args \\ []) do
		room_id = :"#{args}"
		:gen_statem.start_link({:local, room_id}, __MODULE__, [args], [])
		# {:debug, [:trace, :log]}
	end
	
	def start_test do
		:gen_statem.start_link({:local, :test}, __MODULE__, [], [])
	end
	
	##############
	# Client API #
	##############
	
	def join(room_id, player) do
		:gen_statem.cast(room_id, {:join, player.name})
	end
	
	def call(room_id, player) do
		:gen_statem.cast(room_id, {:call, player.name})
	end
	
	def check(room_id, player) do
		:gen_statem.cast(room_id, {:check, player.name})
	end
	
	def raise(room_id, player, amount) do
		:gen_statem.cast(room_id, {:raise, player.name, amount})
	end
	
	def fold(room_id, player) do
		:gen_statem.cast(room_id, {:fold, player.name})
	end
	
	def ready(room_id, player) do
		:gen_statem.cast(room_id, {:ready, player.name})
	end
	
	def leave(room_id, player) do
		:gen_statem.cast(room_id, {:leave, player.name})
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
	
	#############
	# Test API #
	############
	
	def t_join(player) do
		:gen_statem.cast(:test, {:join, player.name})
	end
	
	def t_call(player) do
		:gen_statem.cast(:test, {:call, player.name})
	end
	
	def t_check(player) do
		:gen_statem.cast(:test, {:check, player.name})
	end
	
	def t_raise(player, amount) do
		:gen_statem.cast(:test, {:raise, player.name, amount})
	end
	
	def t_fold(player) do
		:gen_statem.cast(:test, {:fold, player.name})
	end
	
	def t_ready(player) do
		:gen_statem.cast(:test, {:ready, player.name})
	end
	
	def t_leave(player) do
		:gen_statem.cast(:test, {:leave, player.name})
	end
	
	def t_state do
		:gen_statem.call(:test, :state)
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
	
	def init([]), do: {:ok, :idle, %Room{}}
	
	def init([id]) do
		{:ok, :idle, %Room{room_id: id}}
	end
	
	def callback_mode do
		:handle_event_function
	end
	
	###################
	# State Functions #
	###################
	
	def handle_event(:cast, {:join, player}, :idle, %Room{seating: seating} = room) when length(seating) < 1 do
		update = Updater.seating(room, player)
		{:next_state, :idle, update}
	end
	
	def handle_event(:cast, {:join, player}, :idle, room) do
		update =
			room
			|> Updater.seating(player)
			|> Updater.blinds
			|> Updater.set_active
			|> Updater.player_hands
			|> BetTracker.post_blind(@small_blind, :small_blind)
			|> BetTracker.post_blind(@big_blind, :big_blind)
		
			Events.game_started(room.room_id, hd(update.active), update.player_hands)
			Events.advance(room.room_id, hd(update.active))
		
		{:next_state, :pre_flop, update}
	end
	
	def handle_event(:cast, {:join, player}, :between_rounds, %Room{seating: seating} = room) when length(seating) == 1 do
		update =
			room
			|> round_transition(:between_rounds)
			|> Updater.reset_total_paid
			|> Updater.reset_table
			|> Updater.reset_folded
			|> Updater.reset_player_hands
			|> Updater.reset_deck
			|> Updater.reset_stats
			|> Updater.reset_winner
			|> Updater.reset_winning_hand
			|> Updater.reset_pot
			|> Updater.reset_all_in
			|> Updater.seating(player)
			|> Updater.blinds
			|> Updater.set_active
			|> Updater.player_hands
			|> BetTracker.post_blind(@small_blind, :small_blind)
			|> BetTracker.post_blind(@big_blind, :big_blind)
			
			Events.game_started(room.room_id, hd(update.active), update.player_hands)
			Events.advance(room.room_id, hd(update.active))
			
		{:next_state, :pre_flop, update}
	end
	
	def handle_event(:cast, {:join, player}, state, %Room{seating: seating} = room) when length(seating) <= 7 do
		update =
			room
			|> Updater.seating(player)
		{:next_state, state, update}
	end
	
	def handle_event(:cast, {:join, _player}, state, room), do: {:next_state, state, room}
	
	def handle_event(:cast, {:leave, player}, _state, %Room{seating: seating} = room) when length(seating) == 1 do
		update = 
			room
			|> Updater.reset_table_state
			|> Updater.remove_from_seating(player)
		{:next_state, :idle, update}
	end
	
	def handle_event(:cast, {:leave, player}, state, %Room{seating: seating} = room) do
		seated_players = Enum.map(seating, fn {pl, _num} -> pl end)
		update =
			case player in seated_players do
				true ->
					room
					|> Updater.remove_from_seating(player)
					|> Updater.reindex_seating
					|> Updater.advance_active
				_ -> room
			end
		{:next_state, state, update}
	end
	
	def handle_event(:cast, {:call, player}, state, %Room{called: called, active: active} = room) 
	when length(called) < length(active) - 1 do
		update =
			room
			|> BetTracker.call(player)
		{:next_state, state, update, @timeout}
	end
	
	def handle_event(:cast, {:call, player}, state, %Room{all_in: all_in, folded: folded, seating: seating} = room) 
	when length(all_in) + length(folded) == length(seating) - 1 and state in @non_terminal_states do
		update = 
			room
			|> BetTracker.call(player)
			|> round_transition(state)
		{:next_state, :game_over, update, [{:next_event, :internal, :handle_all_in}]}
	end
	
	def handle_event(:cast, {:call, player}, state, room) when state in @non_terminal_states do
		update = 
			room
			|> BetTracker.call(player)
			|> round_transition(state)
		
		{all_in, folded, seating} = {update.all_in, update.folded, update.seating}
		case (length(all_in) + length(folded) == length(seating) - 1) do
			true ->
				{:next_state, :game_over, update, [{:next_event, :internal, :handle_all_in}]}
			_ ->
				{:next_state, advance_state(state), update, @timeout}
		end
	end
	
	def handle_event(:cast, {:call, player}, :river, room) do
		update = 
			room
			|> BetTracker.call(player)
		{:next_state, :game_over, update, [{:next_event, :internal, :reward_winner}]}	
	end
	
	def handle_event(:cast, {:fold, player}, state, %Room{active: active, all_in: all_in} = room)
	when length(active) == 2 or length(all_in) >= 1 and length(active) == 1 do
		update =
			room
			|> BetTracker.fold(player)
			|> round_transition(state)
		{:next_state, :game_over, update, [{:next_event, :internal, :handle_fold}]}
	end
	
	def handle_event(:cast, {:fold, player}, state, %Room{called: called, active: active} = room) when length(called) >= length(active) - 1 do
		update =
			room
			|> BetTracker.fold(player)
			|> round_transition(state)
		{:next_state, advance_state(state), update, @timeout}
	end
	
	def handle_event(:cast, {:fold, player}, state, room) do
		update = 
			room
			|> BetTracker.fold(player)
		{:next_state, state, update, @timeout}
	end
	
	def handle_event(:cast, {:check, player}, state, %Room{to_call: call_amount, round: round, called: called, active: active} = room)
	when length(called) < length(active) - 1 do
		update =
			case call_amount == round[player] || call_amount == 0 do
				true ->
					room
					|> BetTracker.check(player)
				_ ->
					room
			end
		{:next_state, state, update, @timeout}
	end
	
	def handle_event(:cast, {:check, player}, state, %Room{to_call: call_amount, round: round, all_in: all_in, active: active} = room) 
	when length(all_in) >= 1 and length(active) == 1 do
		update = 
			case call_amount == round[player] || call_amount == 0 do
				true ->
					room
					|> BetTracker.check(player)
					|> round_transition(state)
				_ ->
					room
			end
		{:next_state, :game_over, update, [{:next_event, :internal, :handle_all_in}]}
	end
	
	def handle_event(:cast, {:check, player}, state, %Room{to_call: call_amount, round: round, called: called, active: active} = room)
	when length(called) >= length(active) - 1 and state in @non_terminal_states do
		update = 
			case call_amount == round[player] || call_amount == 0 do
				true ->
					room
					|> BetTracker.check(player)
					|> round_transition(state)
				_ ->
					room
			end
		{:next_state, advance_state(state), update, @timeout}
	end
	
	def handle_event(:cast, {:check, player}, :river, %Room{to_call: call_amount, round: round, called: called, active: active} = room)
	when length(called) >= length(active) - 1 do
		update =
			case call_amount == round[player] || call_amount == 0 do
				true ->
					room
					|> BetTracker.check(player)
				_ ->
					room
			end
		{:next_state, :game_over, update, [{:next_event, :internal, :reward_winner}]}
	end
	
	def handle_event(:cast, {:raise, player, amount}, state, %Room{to_call: call_amount} = room) when amount > call_amount do
		update =
			room
			|> BetTracker.raise(player, amount)
		{:next_state, state, update, @timeout}
	end
	
	def handle_event(:internal, :reward_winner, :game_over, %Room{winner: nil} = room) do
		update = 
			room
			|> Updater.stats
			|> Updater.winner
		RewardManager.manage_rewards(update.stats, Map.to_list(update.paid)) |> RewardManager.distribute_rewards(room.room_id)
		Events.winner_message(room.room_id, "#{inspect(update.winner)} wins the round with #{inspect(update.winning_hand.type_string)}")
		Process.sleep(100)
		{:next_state, :between_rounds, update, [{:next_event, :internal, :set_round}]}
	end
	
	def handle_event(:internal, :handle_fold, :game_over, %Room{all_in: all_in, active: active} = room) 
	when length(all_in) == 0 and length(active) == 1 do
		{winner, _} = hd(active)
		update =
			room
			|> Updater.insert_winner(winner)
			|> Updater.insert_stats(winner, 100)
		RewardManager.manage_rewards(update.stats, Map.to_list(update.paid)) |> RewardManager.distribute_rewards(room.room_id)
		Events.winner_message(room.room_id, "#{inspect(update.winner)} wins the round on a fold")
		Process.sleep(100)
		{:next_state, :between_rounds, update, [{:next_event, :internal, :set_round}]}
	end
	
	def handle_event(:internal, :handle_fold, :game_over, %Room{all_in: all_in, active: active} = room)
	when length(all_in) == 1 and length(active) == 0 do
		winner = hd(all_in)
		update =
			room
			|> Updater.insert_winner(winner)
			|> Updater.insert_stats(winner, 100)
		RewardManager.manage_rewards(update.stats, Map.to_list(update.paid)) |> RewardManager.distribute_rewards(room.room_id)
		Events.winner_message(room.room_id, "#{inspect(update.winner)} wins the round on a fold")
		Process.sleep(100)
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
		RewardManager.manage_rewards(update.stats, Map.to_list(update.paid)) |> RewardManager.distribute_rewards(room.room_id)
		Events.winner_message(room.room_id, "#{inspect(update.winner)} wins the round with #{inspect(update.winning_hand.type_string)}")
		Process.sleep(100)
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
		RewardManager.manage_rewards(update.stats, Map.to_list(update.paid)) |> RewardManager.distribute_rewards(room.room_id)
		Events.winner_message(room.room_id, "#{inspect(update.winner)} wins the round with #{inspect(update.winning_hand.type_string)}")
		Process.sleep(100)
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
					|> Updater.reset_winner
					|> Updater.reset_winning_hand
					|> Updater.reset_pot
					|> Updater.reset_all_in
					|> Updater.player_hands
					|> BetTracker.post_blind(@small_blind, :small_blind)
					|> BetTracker.post_blind(@big_blind, :big_blind)
				Events.game_started(room.room_id, hd(update.active), update.player_hands)
				Events.advance(room.room_id, hd(update.active))
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
			|> Updater.reset_winner
			|> Updater.reset_winning_hand
			|> Updater.reset_pot
			|> Updater.reset_all_in
		IO.puts "\nEntering idle state"
		{:next_state, :idle, update}
	end
	
	def handle_event(:internal, :set_round, :between_rounds, room) do
		update =
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
			|> Updater.reset_winner
			|> Updater.reset_winning_hand
			|> Updater.reset_pot
			|> Updater.reset_all_in
		{:next_state, :between_rounds, update}
	end
	
	def handle_event(:timeout, 30000, state, %Room{active: active} = room) 
	when state in [:pre_flop, :flop, :turn, :river] and length(active) > 1 do
	
		{current_player, _} = hd(active)
		update =
			room
			|> BetTracker.fold(current_player)
		case update.active do
			x when length(x) > 1 ->
				{:next_state, state, update}
			_ -> 
				{:next_state, :game_over, update, [{:next_event, :internal, :handle_fold}]}
		end
	end
	
	def handle_event({:call, from}, :player_count, state, %Room{seating: seating} = room) do
		{:next_state, state, room, [{:reply, from, length(seating)}]}
	end
	
	def handle_event({:call, from}, :player_list, state, %Room{seating: seating} = room) do
		players = Enum.map(seating, fn {player, _} -> Repo.get_by(Player, name: player) end)
		{:next_state, state, room, [{:reply, from, players}]}
	end
	
	# DEBUGGING
	def handle_event({:call, from}, :state, state, room) do
		{:next_state, state, room, [{:reply, from, room}]}
	end
	
	# CATCH ALL
	def handle_event(event_type, event_content, state, data) do
		IO.puts "\nUnknown event: #{inspect(event_type)} with content: #{inspect(event_content)} in state: #{inspect(state)}\n"
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
  	|> Updater.reset_active
  	|> Updater.reset_paid_in_round
  	|> Updater.reset_call_amount
  	|> Updater.reset_called
  	|> Updater.table
  	|> Updater.table
  	|> Updater.table
  end
  
  defp round_transition(room, :between_rounds) do
  	room
  	|> Updater.reset_active
  	|> Updater.reset_paid_in_round
  	|> Updater.reset_call_amount
  	|> Updater.reset_called
  end
  
  defp round_transition(room, _state) do
  	room
  	|> Updater.reset_active
  	|> Updater.reset_paid_in_round
  	|> Updater.reset_call_amount
  	|> Updater.reset_called
  	|> Updater.table
  end
end