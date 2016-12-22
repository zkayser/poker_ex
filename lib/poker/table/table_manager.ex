defmodule PokerEx.TableManager do
	use GenServer
	
	alias PokerEx.GameFSM
	alias PokerEx.Player
	alias PokerEx.TableState, as: State
	
	@name :table_manager
	
	def start_link(players) do
		GenServer.start_link(__MODULE__, [players], name: @name)
	end
	
	#######################
	# Interface functions #
	#######################
	
	def seat_player(player) do
		GenServer.cast(@name, {:seat_player, player})
	end
	
	def remove_player(player) do
		GenServer.call(@name, {:remove_player, player})
	end
	
	def start_round do
		GenServer.call(@name, :start_round)
	end
	
	def advance do
		GenServer.call(@name, :advance)
	end
	
	def get_active do
		GenServer.call(@name, :get_active)
	end
	
	def get_big_blind do
		GenServer.call(@name, :get_big_blind)
	end
	
	def get_small_blind do
		GenServer.call(@name, :get_small_blind)
	end
	
	def players_only do
		GenServer.call(@name, :players_only)
	end
	
	def fold(player) do
		GenServer.call(@name, {:fold, player})
	end
	
	def all_in(player) do
		GenServer.call(@name, {:all_in, player})
	end
	
	def clear_round do
		GenServer.call(@name, :clear_round)
	end
	
	def reset_turns do
		GenServer.call(@name, :reset_turns)
	end
	
	def	fetch_data do
		GenServer.call(@name, :fetch_data)
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
		update = %State{ data | seating: seating, length: length(seating)}
		{:noreply, update}
	end
	
	def handle_call({:remove_player, player}, _from, %State{seating: seating, active: active, current_player: cp, next_player: np} = data)
		when not is_nil(cp) do
		new_seating = Enum.map(seating, fn {pl, _} -> pl end) |> Enum.reject(fn pl -> pl == player end) |> Enum.with_index
		now_active = Enum.reject(active, fn {pl, _} -> pl == player end)
		{name, _num} = cp
		{_next_name, _num} = np
		current = if player == name, do: np, else: cp
		
		next = 
			case current do 
				x when x == np ->
					next_player(%State{active: now_active}, np)
				_ -> np
			end
		update = %State{ data | seating: new_seating, active: now_active, current_player: current, next_player: next}
		{:reply, update, update}
	end
	
	def handle_call({:remove_player, player}, _from, %State{seating: seating, active: active} = data) do
		new_seating = Enum.map(seating, fn {pl, _} -> pl end) |> Enum.reject(fn pl -> pl == player end) |> Enum.with_index
		now_active = Enum.reject(active, fn {pl, _} -> pl == player end)
		update = %State{ data | seating: new_seating, active: now_active}
		{:reply, update, update}
	end
	
			#####################
			# Position tracking #
			#####################
			
	def handle_call(:start_round, _from, %State{seating: seating, big_blind: nil, small_blind: nil} = data) do
		[{big_blind, 0}, {small_blind, 1}|_rest] = seating
		
		current_player = Enum.at(seating, 2) || {big_blind, 0}
		next_player = if current_player == big_blind, do: {small_blind, 1}, else: Enum.at(seating, 3) || {big_blind, 0}
		
		update = %State{ data | active: seating, current_player: current_player, next_player: next_player,
				big_blind: big_blind, small_blind: small_blind, current_big_blind: 0, current_small_blind: 1
			}
		{:reply, update, update}
	end
	
	def handle_call(:start_round, _from, %State{seating: seating} = data) do
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
				big_blind: big_blind, small_blind: small_blind, current_big_blind: num, current_small_blind: num2
			}
		{:reply, update, update}
	end
	
	def handle_call(:advance, _from, %State{current_player: {_player, _seat}} = data) do
		update = %State{ data | current_player: data.next_player, next_player: next_player(data)}
		{:reply, update, update}
	end
	
	def handle_call(:reset_turns, _from, data) do
		update = first_turn(data)
		next_player = next_player(update, update.current_player)
		update = %State{ update | next_player: next_player}
		{:reply, update, update}
	end
	
			################
			# Player calls #
			################
	
	def handle_call({:fold, player}, _from, %State{active: active, current_player: {pl, _}} = data) when player == pl do
		update = %State{ data | active: Enum.reject(active, fn {pl, _} -> pl == player end), 
			current_player: data.next_player, next_player: next_player(data)
		}
		{:reply, update, update}
	end
	
	def handle_call({:fold, _}, _, _), do: raise "Illegal operation"
	
	def handle_call({:all_in, player}, _from, %State{active: active, current_player: {pl, _}, all_in: ai} = data) when player == pl do
		update = %State{ data | active: Enum.reject(active, fn {pl, _} -> pl == player end),
			current_player: data.next_player, next_player: next_player(data), all_in: ai ++ player
		}
		{:reply, update, update}
	end
	
	def handle_call({:all_in, _}, _, _), do: raise "Illegal operation"
	
			#########
			# Clear #
			#########
	
	def handle_call(:clear_round, _from, %State{seating: seating, big_blind: bb, small_blind: sb, current_small_blind: csb} = state) do
		[head|tail] = seating
		update = %State{seating: tail ++ [head], big_blind: sb, small_blind: next_seated(state, {sb, csb})}
		{:reply, update, update}
	end
	
			#################
			# Data fetchers #
			#################
			
	def handle_call(:get_active, _from, %State{active: active} = data) do
		{:reply, active, data}
	end
			
	def handle_call(:fetch_data, _from, data), do: {:reply, data, data}
	
	def handle_call(:get_big_blind, _from, %State{big_blind: big_blind} = data) do
		{:reply, big_blind, data}
	end
	
	def handle_call(:get_small_blind, _from, %State{small_blind: small_blind} = data) do
		{:reply, small_blind, data}
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
	
	defp next_player(%State{active: active, next_player: {player, seat}}) do
		next = 
			case Enum.drop_while(active, fn {_, num} -> num <= seat end) do
				[] -> List.first(active)
				[{pl, s}|_rest] -> {pl, s}
				_ -> raise ArgumentError
			end
		
	end
	
	defp next_player(%State{active: active}, {player, seat}) do
		next = 
			case Enum.drop_while(active, fn {_, num} -> num <= seat end) do
				[] -> List.first(active)
				[{pl, s}|_rest] -> {pl, s}
				_ -> raise "Something went wrong"
			end
	end
	
	defp next_seated(%State{seating: seating}, {player, seat}) do
		next = 
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