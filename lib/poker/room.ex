defmodule PokerEx.Room do
	alias PokerEx.BetBuffer, as: Buffer
	alias PokerEx.BetServer
	alias PokerEx.Player
	alias PokerEx.Events
	alias PokerEx.TableManager
	alias PokerEx.HandServer
	alias PokerEx.RewardManager
	alias PokerEx.Room, as: Room
	
	## URGENT: A problem arises when there are only two players
	## and one goes all in. The game does not advance and 
	## everything is left hanging.
	
	defstruct buffer: %{called: []}, bet_server: nil, hand_server: nil, table_manager: nil
	
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
	
	def call(player) do
		:gen_statem.call(@name, {:call, player.name})
	end
	
	def check(player) do
		:gen_statem.call(@name, {:check, player.name})
	end
	
	def raise(player, amount) do
		:gen_statem.call(@name, {:raise, player.name, amount})
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
	
	def data do
	  :gen_statem.call(@name, :data)
	end
	
	def active do
		:gen_statem.call(@name, :active)
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
		:handle_event_function
	end
	
	###################
	# State Functions #
	###################
	
	def handle_event(:enter, old_state, state, data) do
	  IO.puts "Entering #{inspect(state)} from #{inspect(old_state)}"
	  {:next_state, state, data}
	end
	
	def handle_event(:info, :setup, _state, _data) do
	  {:ok, bet_server} = BetServer.start_link
	  {:ok, table_manager} = TableManager.start_link([])
		{:ok, hand_server} = HandServer.start_link()
		Events.start_link
		buffer = Buffer.new |> Map.put(:table_manager, table_manager) |> Map.put(:bet_server, bet_server) |> Map.put(:winner, nil)
		{:next_state, :idle, %Room{bet_server: bet_server, table_manager: table_manager, hand_server: hand_server, buffer: buffer}}
	end
	
	def handle_event({:call, from}, {:join, player}, :idle, %Room{buffer: buffer} = data) do
	  {bs, hs, tm} = {data.bet_server, data.hand_server, data.table_manager}
	  TableManager.seat_player(tm, player)
	  
	  case length(TableManager.seating(tm)) do
	    x when x > 1 ->
	     TableManager.start_round(tm)
	     {buffer, _bet_amount} = Buffer.raise(buffer, TableManager.get_small_blind(tm), @small_blind, 0)
	     {updated_buffer, bet_amount} = Buffer.raise(buffer, TableManager.get_big_blind(tm), @big_blind, BetServer.get_to_call(bs))
	     update = %Room{data | buffer: updated_buffer}
	     HandServer.deal_first_hand(hs, TableManager.players_only(tm))
	     Events.game_started(TableManager.current_player(tm), HandServer.player_hands(hs))
	    {:next_state, :pre_flop, update, [{:reply, from, {:game_begin, "#{player} joined", TableManager.active(tm), HandServer.player_hands(hs)}}]}
	   _ -> 
	    {:next_state, :idle, data, [{:reply, from, "#{player} joined"}]}
	  end
	end
	
	def handle_event({:call, from}, {:call, player}, :river, %Room{buffer: %{called: called} = buffer} = data) do
	  {hs, tm} = {data.hand_server, data.table_manager}
	  
	  active = TableManager.active(tm)
	  all_in_round = TableManager.all_in_round(tm)
	  case (length(active) + length(all_in_round) - 1) > length(called) do
			true ->
				buffer = Buffer.call(buffer, player)
				update = %Room{ data | buffer: buffer}
				{:next_state, :river, update, [{:reply, from, "#{player} called"}]}
			_ ->
				buffer = Buffer.call(buffer, player)
				updated_buffer = Buffer.reset_called(buffer)
				HandServer.score(hs)
				update = %Room{ data | buffer: updated_buffer}
				{:next_state, :game_over, update, 
				  [{:next_event, :internal, {:reward_winner, from}}]
				}
		end
	end
	
	def handle_event({:call, from}, {:call, player}, state, %Room{buffer: %{called: called} = buffer} = data) do
	  {bs, hs, tm} = {data.bet_server, data.hand_server, data.table_manager}
	  active = TableManager.active(tm)
	  all_in_round = TableManager.all_in_round(tm)
	  case (length(active) + length(all_in_round) - 1) > length(called) do
			true ->
			  buffer = Buffer.call(buffer, player)
				update = %Room{ data | buffer: buffer}
				{:next_state, state, update, [{:reply, from, {"#{player} called", TableManager.active(tm)}}]}
			_ ->
				if length(TableManager.active(tm)) == 1 && length(TableManager.get_all_in(tm)) > 0 do
				  buffer = Buffer.call(buffer, player)
					update = %Room{ data | buffer: buffer}
					{:next_state, :game_over, update, [{:next_event, :internal, {:auto_complete, from}}]}
				else
				  buffer = Buffer.call(buffer, player)
					updated_buffer = Buffer.reset_called(buffer)
					advance_round(state, tm, hs, bs)
					update = %Room{ data | buffer: updated_buffer}
					{:next_state, advance_state(state), update, [{:reply, from, {TableManager.active(tm), HandServer.table(hs)}}]}
				end
		end
	end
	
	def handle_event({:call, from}, {:raise, player, amount}, state, %Room{buffer: buffer} = data) do
	  bs = data.bet_server
	  case amount > BetServer.get_to_call(bs) do
	    true ->
	      {buffer, bet_amount} = Buffer.raise(buffer, player, amount, BetServer.get_to_call(bs))
	      update = %Room{ data | buffer: buffer}
	      {:next_state, state, update, [{:reply, from, "#{player} raised by #{bet_amount} to #{BetServer.get_to_call(bs)}"}]}
	    _ ->
	      {:next_state, state, data, [{:reply, from, "#{player} tried to raise but did not specify an amount above #{inspect(BetServer.pot(bs))}"}]}
	  end
	end
	
	def handle_event({:call, from}, {:check, player}, :river, %Room{buffer: %{called: called} = buffer} = data) do
	  {bs, hs, tm} = {data.bet_server, data.hand_server, data.table_manager}
	  active = TableManager.active(tm)
	  all_in_round = TableManager.all_in_round(tm)
	  case (length(active) + length(all_in_round) - 1) > length(called) do
			true ->
				buffer = Buffer.check(buffer, player, BetServer.get_paid_in_round(bs, player), BetServer.get_to_call(bs))
				update = %Room{ data | buffer: buffer}
				{:next_state, :river, update, [{:reply, from, "#{player} checked"}]}
			_ ->
				buffer = Buffer.call(buffer, player)
				updated_buffer = Buffer.reset_called(buffer)
				HandServer.score(hs)
				update = %Room{ data | buffer: updated_buffer}
				{:next_state, :game_over, update, [{:next_event, :internal, {:reward_winner, from}}]}
		end
	end
	
	def handle_event({:call, from}, {:check, player}, state, %Room{buffer: %{called: called} = buffer} = data) do
	  {bs, hs, tm} = {data.bet_server, data.hand_server, data.table_manager}
	  active = TableManager.active(tm)
	  all_in_round = TableManager.all_in_round(tm)
	  case (length(active) + length(all_in_round) - 1) > length(called) do
			true ->
				buffer = Buffer.check(buffer, player, BetServer.get_paid_in_round(bs, player), BetServer.get_to_call(bs))
				update = %Room{ data | buffer: buffer}
				{:next_state, state, update, [{:reply, from, "#{player} checked"}]}
			_ ->
				buffer = Buffer.check(buffer, player, BetServer.get_paid_in_round(bs, player), BetServer.get_to_call(bs))
				advance_round(state, tm, hs, bs)
				update = %Room{ data | buffer: buffer}
				{:next_state, advance_state(state), update, [{:reply, from, {TableManager.active(tm), HandServer.table(hs)}}]}
		end
	end
	
	def handle_event({:call, from}, {:fold, player}, state, %Room{buffer: buffer} = data) do
	  {bs, tm} = {data.bet_server, data.table_manager}
	  case length(TableManager.active(tm)) > 2 do
			true ->
				TableManager.fold(tm, player)
				{:next_state, state, data, [{:reply, from, "#{player} folded"}]}
			_ ->
				if length(TableManager.get_all_in(tm)) > 0 do
					unless length(TableManager.active(tm)) == 2 do
						{:next_state, :game_over, data, [{:next_event, :internal, {:auto_complete, from}}]}
					else 
					  TableManager.fold(tm, player)
						{:next_state, state, data, [{:reply, from, "#{player} folded"}]}
					end
				else
					TableManager.fold(tm, player)
					[{winner, _seat}|_] = TableManager.active(tm)
					update = %Room{ data | buffer: Map.put(buffer, :winner, winner)}
					{:next_state, :game_over, update,
					  [{:reply, from, {"#{winner} wins the pot on fold", BetServer.pot(bs)}}, {:next_event, :internal, :reward_winner}]
					}
				end
		end
	end
	
	def handle_event({:call, from}, :data, state, data) do
	  {:next_state, state, data, [{:reply, from, data}]}
	end
	
	def handle_event(:internal, :reward_winner, _state, %Room{buffer: %{winner: winner} = buffer, table_manager: tm, bet_server: bs} = data) when not is_nil(winner) do
	  send(self, {:reward_winner, [{winner, 100}], BetServer.pot(bs)})
	  TableManager.clear_round(tm)
	  update = %Room{ data | buffer: Buffer.clear(buffer)}
	  {:next_state, :between_rounds, update, [{:next_event, :internal, :set_round}]}
	end
	
	def handle_event(:internal, {:reward_winner, from}, _state, %Room{buffer: buffer, table_manager: tm, hand_server: hs, bet_server: bs} = data) do
	  send(self, {:reward_winner, HandServer.stats(hs), BetServer.paid(bs), TableManager.active(tm), 
	              TableManager.get_all_in(tm), HandServer.player_hands(hs), from
	             })
		TableManager.clear_round(tm)
		BetServer.clear(bs)
		HandServer.clear(hs)
		update = %Room{data | buffer: Buffer.clear(buffer)}
		{:next_state, :between_rounds, update, [{:timeout, 1000, :set_round}]}
	end
	
	def handle_event(:internal, {:auto_complete, from}, state, %Room{hand_server: hs} = data) do
	  case length(HandServer.table(hs)) do
	    x when x < 5 ->
	      HandServer.deal_one(hs)
	      {:next_state, state, data, 
	        [{:next_event, :internal, {:auto_complete, from}}]
	      }
	    x when x >= 5 ->
	      HandServer.score(hs)
	      {:next_state, :game_over, data, [{:next_event, :internal, {:reward_winner, from}}]}
	  end
	end
	
	def handle_event(:internal, :set_round, _state, %Room{buffer: buffer, table_manager: tm, hand_server: hs, bet_server: bs} = data) do
	  BetServer.clear(bs)
	  HandServer.clear(bs)
	  
	  case length(TableManager.seating(tm)) do
	    x when x > 1 ->
		    if TableManager.start_round(tm) == :not_enough_players do
		    	{:next_state, :idle, data}
		    else
		    	{buffer, _bet_amount} = Buffer.raise(buffer, TableManager.get_small_blind(tm), @small_blind, 0)
					{buffer, bet_amount} = Buffer.raise(buffer, TableManager.get_big_blind(tm), @big_blind, BetServer.get_to_call(bs))
					update = %Room{ data | buffer: buffer}
					HandServer.deal_first_hand(hs, TableManager.players_only(tm))
					Events.game_started(TableManager.current_player(tm), HandServer.player_hands(hs))
					{:next_state, :pre_flop, update}
		    end
			_ -> 
				{:next_state, :idle, data} 
	  end
	end
	
	def handle_event({:call, from}, {:join, player}, state, %Room{buffer: buffer, table_manager: tm, hand_server: hs, bet_server: bs} = data) do
	  TableManager.seat_player(tm, player)
	  table_state = TableManager.fetch_data(tm)
	  
	  # Empty active list and empty all_in list means that no game is ongoing
	  case {length(table_state.seating), table_state.active, table_state.all_in} do
	    {x, [], []} when x > 1 ->
	      TableManager.start_round(tm)
	      {buffer, _bet_amount} = Buffer.raise(buffer, TableManager.get_small_blind(tm), @small_blind, 0)
	      {buffer, bet_amount} = Buffer.raise(buffer, TableManager.get_big_blind(tm), @big_blind, BetServer.get_to_call(bs))
	      update = %Room{ data | buffer: buffer}
	      {:next_state, :pre_flop, update, [:reply, from, {"The first hand has been dealt", HandServer.player_hands(hs)}]}
	    _ ->
	      {:next_state, state, data, [{:reply, from, "#{player} joined the room"}]}
	  end
	end
	
	def handle_event(:cast, :clear, _state, %Room{table_manager: tm, hand_server: hs, bet_server: bs} = data) do
	  TableManager.clear_round(tm)
	  HandServer.clear(hs)
	  BetServer.clear(bs)
	  {:next_state, :idle, data}
	end
	
	def handle_event({:call, from}, :active, state, data) do
		active = TableManager.active(data.table_manager)
		{:next_state, state, data, [{:reply, from, active}]}
	end
	
	def handle_event({:call, from}, :get_state, state, data) do
	  {:next_state, state, data,
	    [
	      {:reply, from, 
	      "Current state: #{inspect(state)}\n
	      Hand server: #{inspect(HandServer.fetch_data(data.hand_server))}\n
	      Bet server: #{inspect(BetServer.fetch_data(data.bet_server))}\n
	      Table manager: #{inspect(TableManager.fetch_data(data.table_manager))}"}
	    ]
	  }
	end
	
	def handle_event(:info, {:reward_winner, stats, paid, active, all_in, hands, from}, state, data) do
	  players = active ++ all_in |> Enum.map(fn {pl, _seat} -> pl end)
	  new_stats = Enum.filter(stats, fn {pl, _score} -> pl in players end) |> Enum.sort(fn {_, score1}, {_, score2} -> score1 > score2 end)
	  RewardManager.manage_rewards(new_stats, Map.to_list(paid)) |> RewardManager.distribute_rewards
	  {winner, _} = List.first(new_stats)
	  {^winner, winner_hand} = Enum.find(hands, fn {pl, _hand} -> pl == winner end)
	  Events.winner_message("#{winner} wins the round with #{winner_hand.type_string}")
	  reply = {:game_finished, "#{winner} wins the round with #{inspect(winner_hand.type_string)}"}
	  {:next_state, state, data, [{:reply, from, reply}, {:next_event, :internal, :set_round}]}
	end
	
	def handle_event(:info, {:reward_winner, [{winner, 100}], pot}, state, data) do
	  Player.reward(winner, pot)
	  Events.game_over(winner, pot)
	  {:next_state, state, data}
	end
	
	def handle_event(event_type, event_content, state, data) do
	  IO.puts "Unknown message received: "
	  IO.inspect(event_type)
	  IO.inspect(event_content)
	  IO.inspect(state)
	  IO.inspect(data)
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
  
  defp advance_round(:pre_flop, table_manager, hand_server, bet_server) do
    TableManager.reset_turns(table_manager)
    HandServer.deal_flop(hand_server)
    BetServer.reset_round(bet_server)
  end
  defp advance_round(_state, table_manager, hand_server, bet_server) do
    TableManager.reset_turns(table_manager)
    HandServer.deal_one(hand_server)
    BetServer.reset_round(bet_server)
  end
end