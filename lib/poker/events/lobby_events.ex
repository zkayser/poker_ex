defmodule PokerEx.LobbyEvents do
  alias PokerExWeb.Endpoint

  def update_number_players(room, number) do
    Endpoint.broadcast("players:lobby", "update_num_players", %{room: room, number: number})
  end

  def update_player_count(%PokerEx.Room{room_id: id, seating: seating}) do
  	Endpoint.broadcast("lobby:lobby", "update_player_count", %{room: id, player_count: length(seating)})
  end

  def update_player_count(room), do: room
end