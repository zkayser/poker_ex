defmodule PokerEx.TableManager do
	use GenServer
	
	alias PokerEx.TableState, as: State
	alias PokerEx.Events
	
	@name :table_manager
	
	def start_link(players) do
		GenServer.start_link(__MODULE__, [players])
	end
	
	#######################
	# Interface functions #
	#######################
	
	def seat_player(pid, player) do
		GenServer.cast(pid, {:seat_player, player})
	end
	
	def remove_player(pid, player) do
		GenServer.call(pid, {:remove_player, player})
	end
	
	def start_round(pid) do
		GenServer.call(pid, :start_round)
	end
	
	def advance(pid) do
		GenServer.call(pid, :advance)
	end
	
	def active(pid) do
		GenServer.call(pid, :active)
	end
	
	def current_player(pid) do
		GenServer.call(pid, :current_player)
	end
	
	def seating(pid) do
		GenServer.call(pid, :seating)
	end
	
	def get_big_blind(pid) do
		GenServer.call(pid, :get_big_blind)
	end
	
	def get_small_blind(pid) do
		GenServer.call(pid, :get_small_blind)
	end
	
	def get_all_in(pid) do
		GenServer.call(pid, :get_all_in)
	end
	
	def all_in_round(pid) do
		GenServer.call(pid, :all_in_round)
	end
	
	def players_only(pid) do
		GenServer.call(pid, :players_only)
	end
	
	def fold(pid, player) do
		GenServer.call(pid, {:fold, player})
	end
	
	def all_in(pid, player) do
		GenServer.cast(pid, {:all_in, player})
	end
	
	def clear_round(pid) do
		GenServer.call(pid, :clear_round)
	end
	
	def reset_turns(pid) do
		GenServer.call(pid, :reset_turns)
	end
	
	def	fetch_data(pid) do
		GenServer.call(pid, :fetch_data)
	end
	
	#############
	# Callbacks #
	#############
	
	def init([players]) do
		send(self(), {:setup, players})
		{:ok, %State{}}
	end
	
	
			########################
			# Seating and removing #
			########################
	
	def handle_cast({:seat_player, player}, data) do
		seat_number = length(data.seating)
		seating = [{player, seat_number}|Enum.reverse(data.seating)] |> Enum.reverse
		Events.player_joined(player, seat_number)
		update = %State{ data | seating: seating, length: length(seating)}
		{:noreply, update}
	end
	
	def handle_cast({:all_in, player}, %State{current_player: {_pl, seat}, all_in: ai, all_in_round: air} = data) do
		update = %State{ data | all_in: ai ++ [{player, seat}], all_in_round: air ++ [{player, seat}]}
		{:noreply, update}
	end
	
	def handle_call({:remove_player, player}, _from, %State{seating: seating, active: active} = data) do
		Events.player_left(player)
		new_seating = Enum.map(seating, fn {pl, _} -> pl end) |> Enum.reject(fn pl -> pl == player end) |> Enum.with_index
		case active do
			[] ->
				update = %State{ data | seating: new_seating}
				{:reply, update, update}
			_ ->
				[head|tail] = active
				update = %State{ data | seating: new_seating, active: tail, current_player: hd(tail)}
				{:reply, update, update}
		end
	end
		
			#####################
			# Position tracking #
			#####################
			
	def handle_call(:start_round, _from, %State{seating: seating, big_blind: nil, small_blind: nil} = data) do
		[{big_blind, 0}, {small_blind, 1}|rest] = seating
		
		case length(rest) do
			x when x >= 2 ->
				[current, next|_] = rest
				update = %State{ data | active: rest ++ [{small_blind, 1}, {big_blind, 0}], current_player: current, next_player: next,
					big_blind: big_blind, small_blind: small_blind, current_big_blind: 0, current_small_blind: 1
				}
				{:reply, update, update}
			x when x == 1 ->
				[current|_] = rest
				update = %State{ data | active: rest ++ [{small_blind, 1}, {big_blind, 0}], current_player: current, next_player: {small_blind, 1},
					big_blind: big_blind, small_blind: small_blind, current_big_blind: 0, current_small_blind: 1
				}
				{:reply, update, update}
			x when x == 0 ->
				update = %State{ data | active: [{small_blind, 1}, {big_blind, 0}], current_player: {small_blind, 1}, next_player: {big_blind, 0},
					big_blind: big_blind, small_blind: small_blind, current_big_blind: 0, current_small_blind: 1
				}
				{:reply, update, update}
		end
	end
	
	def handle_call(:start_round, from, %State{seating: seating} = data) do
		# Remove players who run out of chips
		out_of_chips = PokerEx.AppState.players |> Enum.map(
			fn %PokerEx.Player{name: name, chips: chips} -> 
				if chips == 0, do: name, else: nil
			end
			)
		
		seating = Enum.reject(seating, fn {player, _} -> player in out_of_chips end)
		
		try do
			[{big_blind, num}, {small_blind, num2}|_rest] = seating
			
			current_player = 
				case Enum.any?(seating, fn {_, seat} -> seat > num2 end) do
					true -> Enum.find(seating, fn {_, seat} ->  seat == num2 + 1 end)
					_ -> Enum.find(seating, fn {_, seat} -> seat == 0 end)
				end
			
			next_player = 
				case current_player do
					{_, 0} -> Enum.find(seating, fn {_, seat} -> seat == 1 end)
					_ -> 
						if Enum.any?(seating, fn {_, seat} -> seat > num2 + 1 end) do
							Enum.find(seating, fn {_, seat} -> seat == num2 + 2 end)
						else
							Enum.find(seating, fn {_, seat} -> seat == 0 end)
						end
				end
			
			update = %State{ data | active: seating, current_player: current_player, next_player: next_player,
					big_blind: big_blind, small_blind: small_blind, current_big_blind: num, current_small_blind: num2,
					seating: seating
				}
			{:reply, update, update}
		
		rescue
			_ -> GenServer.reply(from, :not_enough_players)
			[{player, _num}] = seating
			{:noreply, %State{ data | seating: [{player, 0}], big_blind: nil, small_blind: nil}}
		end
	end
	
	def handle_call(:advance, _from, %State{active: active, all_in: all_in} = data) do
		leader_all_in? = hd(active) in all_in
		case length(active) do
			x when x >= 3 ->
				[current, next, on_deck|_rest] = active
				[head|tail] = active
				update = %State{ data | current_player: next, next_player: on_deck}
				Events.advance(next)
				update = if leader_all_in?, do: %State{ update | active: tail}, else: %State{ update | active: tail ++ [head]}
				{:reply, "#{inspect(next)} is up", update}
			x when x == 2 ->
				[current, next] = active
				update = %State{ data | current_player: next, next_player: current}
				Events.advance(next)
				update = if leader_all_in?, do: %State{ update | active: [next]}, else: %State{ update | active: [next, current]}
				{:reply, "#{inspect(next)} is up", update}
			x when x == 1 ->
				{:reply, "Cannot advance. Only one player is active", data}
			x when x == 0 ->
				{:reply, data, data}
		end
	end
	
	def handle_call(:reset_turns, _from, data) do
		update = first_turn(data)
		next_player = next_player(update, update.current_player)
		# Update the next player and reset all_in_round back to an empty list
		update = %State{ update | next_player: next_player, all_in_round: []}
		{:reply, update, update}
	end
	
			################
			# Player calls #
			################
	
	def handle_call({:fold, player}, _from, %State{active: active, current_player: {pl, _}} = data) when player == pl do
		[_|rest] = active
		[head|tail] = rest
		case length(tail) do
			x when x >= 1 ->
				update = %State{ data | active: rest, current_player: head, next_player: hd(tail)}
				{:reply, update, update}
			_ ->
				update = %State{ data | active: rest, current_player: head, next_player: nil}
				{:reply, update, update}
		end
	end
	
	def handle_call({:fold, _}, _, _), do: raise "Illegal operation"
	
			#########
			# Clear #
			#########
	
	def handle_call(:clear_round, _from, %State{seating: seating, small_blind: sb, current_small_blind: csb} = state) do
		[head|tail] = seating
		{new_sb, new_csb} = next_seated(state, {sb, csb})
		update = %State{seating: tail ++ [head], big_blind: sb, current_big_blind: csb, small_blind: new_sb, current_small_blind: new_csb}
		{:reply, update, update}
	end
	
			#################
			# Data fetchers #
			#################
			
	def handle_call(:active, _from, %State{active: active} = data) do
		{:reply, active, data}
	end
	
	def handle_call(:current_player, _from, %State{active: active} = data) do
		{:reply, hd(active), data}
	end
	
	def handle_call(:seating, _from, %State{seating: seating} = data) do
		{:reply, seating, data}
	end
			
	def handle_call(:fetch_data, _from, data), do: {:reply, data, data}
	
	def handle_call(:get_big_blind, _from, %State{big_blind: big_blind} = data) do
		{:reply, big_blind, data}
	end
	
	def handle_call(:get_small_blind, _from, %State{small_blind: small_blind} = data) do
		{:reply, small_blind, data}
	end
	
	def handle_call(:get_all_in, _from, %State{all_in: all_in} = data) do
		{:reply, all_in, data}
	end
	
	def handle_call(:all_in_round, _from, %State{all_in_round: air} = data) do
		{:reply, air, data}
	end
	
	def handle_call(:players_only, _from, %State{active: active} = data) do
		players = for {player, _} <- active, do: player
		{:reply, players, data}
	end
	
			#########
			# Setup #
			#########
			
	def handle_info({:setup, players}, _state) do
		data = %State{seating: Enum.with_index(players)}
		{:noreply, data}
	end
	
			#############
			# Catch all #
			#############
	
	def handle_info(event_content, data) do
		IO.puts "\nReceived unknown message: \n"
		IO.inspect(event_content)
		IO.inspect(data)
		IO.puts "\n"
		{:noreply, data}
	end
	
	#####################
	# Utility functions #
	#####################
	
	defp next_player(%State{active: active}, {_player, seat}) do
			case Enum.drop_while(active, fn {_, num} -> num <= seat end) do
				[] -> List.first(active)
				[{pl, s}|_rest] -> {pl, s}
				_ -> raise "Something went wrong"
			end
	end
	
	defp next_seated(%State{seating: seating}, {_player, seat}) do
			case Enum.drop_while(seating, fn {_, num} -> num <= seat end) do
				[] -> List.first(seating)
				[{pl, s}|_rest] -> {pl, s}
				_ -> raise "Something went wrong"
			end
	end
	
	defp first_turn(%State{active: active, big_blind: big_blind} = state) do
		case Enum.find(active, fn {pl, _num} -> big_blind == pl end) do
			true -> %State{ state | current_player: {big_blind, state.current_big_blind}}
			_ -> %State{ state | current_player: next_player(state, {big_blind, state.current_big_blind})}
		end
	end
end