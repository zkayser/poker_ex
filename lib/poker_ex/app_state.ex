defmodule PokerEx.AppState do
	alias PokerEx.Player
	
	# This module is turning out to be more of a player
	# database/state manager than an app_state manager.
	# It may be best just to morph it into a player
	# state manager that can track players across
	# the application, no matter what channel they
	# are joined on and what rooms/tables/games 
	# they may be involved in.
	
	def start_link do
		Agent.start_link(fn -> %{} end, name: __MODULE__)
	end
	
	def put(player) do
		Agent.update(__MODULE__, &Map.update(&1, :players, [player], fn list -> list ++ [player] end))
		player
	end
	
	def get(%Player{name: player_id}) do
		players
		|> Enum.filter(fn player -> player.name == player_id end)
		|> Kernel.hd
	end
	
	def get(name) do
		players
		|> Enum.filter(fn player -> player.name == name end)
		|> Kernel.hd
	end
	
	def get_and_update(%Player{chips: chips} = player) do
		player |> delete
		updated = %Player{player | chips: chips} |> put
		get(updated)
	end
	
	def players do
		Agent.get(__MODULE__, &Map.get(&1, :players))
	end
	
	def update(player) do
		player |> delete |> put
	end
	
	def delete(%Player{name: player_name}) do
		Agent.update(__MODULE__, &Map.update(&1, :players, &1, fn list -> remove_player(list, player_name) end))
	end
	
	defp remove_player([], _), do: []
	defp remove_player(list, name) do
		list
		|> Enum.reject(fn player -> player.name == name end)
	end
end