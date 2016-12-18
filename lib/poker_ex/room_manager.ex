defmodule PokerEx.RoomManager do
	alias PokerEx.Player
	alias PokerEx.Game
	@rooms 1..10 |> Enum.to_list
	
	def start_link do
		Agent.start_link(fn -> %{
			1 => %{players: []}, 2 => %{players: []}, 3 => %{players: []}, 4 => %{players: []},
			5 => %{players: []}, 6 => %{players: []}, 7 => %{players: []}, 8 => %{players: []},
			9 => %{players: []}, 10 => %{players: []}
		} end, name: __MODULE__)
	end
	
	def join_room(room, %Player{name: _} = player) when room in @rooms do
		players = get_players_for(room)
		case length(players) do
			x when x <= 9 ->
				Agent.update(__MODULE__, &Map.update!(&1, room, 
					fn rm_state -> Map.update!(rm_state, :players, 
						fn list -> [player|list] end) 
					end))
			_ -> {:error, :room_full}
		end
	end
	
	def leave_room(room, %Player{name: name}) when room in @rooms do
		players = get_players_for(room) |> Enum.reject(&(&1.name == name))
		Agent.update(__MODULE__, &Map.update!(&1, room, 
			fn rm_state -> Map.put(rm_state, :players, players)
			end
		))
	end
	
	def start_game(room) when room in @rooms do
		players = get_players_for(room)
		Agent.update(__MODULE__, &Map.update!(&1, room,
			fn rm_state -> Map.put(rm_state, :game, Game.start(players))
			end
		))
		Agent.cast(__MODULE__, &Map.update!(&1, room,
			fn rm_state -> Map.delete(rm_state, :players)
			end
		))
	end
	
	def fold(room, player) do
		transfer_player_to_wait(room, player)
		get_game_for(room) |> Game.fold(player) |> update_game_for(room)
	end
	
	def raise_pot(room, player, amount) do
		get_game_for(room) |> Game.raise_pot(player, amount) |> update_game_for(room)
	end
	
	def check(room, player) do
		get_game_for(room) |> Game.check(player) |> update_game_for(room)
	end
	
	def call(room, player) do
		get_game_for(room) |> Game.call_pot(player) |> update_game_for(room)
	end
	
	def hand_for(room, player) do
		get_game_for(room) 
		|> Map.get(:players) 
		|> Enum.filter(&(&1.name == player.name))
		|> Kernel.hd
		|> Map.get(:hand)
	end
	
	def pot_for(room) do
		get_game_for(room) |> Map.get(:pot)
	end
	
	def get_table_for(room) do
		get_game_for(room) |> Map.get(:table)
	end
	
	def get_status_for(room) do
		get_game_for(room) |> Map.get(:status)
	end
	
	def get_room(room) when room in @rooms do
		Agent.get(__MODULE__, &Map.get(&1, room))
	end
	
	def get_players_for(room) when room in @rooms do
		get_room(room) |> Map.get(:players)
	end
	
	def get_game_for(room) when room in @rooms do
		get_room(room) |> Map.get(:game)
	end
	
	defp update_game_for(game, room) when room in @rooms do
		Agent.update(__MODULE__, &Map.update!(&1, room,
			fn rm_state -> Map.put(rm_state, :game, game)
			end
		))
	end
	
	defp transfer_player_to_wait(room, player) do
		Agent.cast(__MODULE__, &Map.update!(&1, room, 
			fn rm_state -> 
				Map.update(rm_state, :players, [player], 
					fn list -> [player|list] 
					end)
			end))
	end
	
	defp transfer_players_to_wait(room, players) when is_list(players) do
		Enum.each(players, &transfer_player_to_wait(room, &1))
	end
end