defmodule PokerEx.LobbyEvents do
  alias PokerExWeb.Endpoint

  def update_number_players(game, number) do
    Endpoint.broadcast("players:lobby", "update_num_players", %{game: game, number: number})
  end

  def update_player_count(%PokerEx.Room{room_id: id, seating: seating}) do
    Endpoint.broadcast("lobby:lobby", "update_player_count", %{
      room: id,
      player_count: length(seating)
    })
  end

  def update_player_count(%PokerEx.GameEngine.Impl{game_id: id, seating: %{arrangement: seating}}) do
    Endpoint.broadcast("lobby:lobby", "update_player_count", %{
      game: id,
      player_count: length(seating)
    })
  end

  def update_player_count(game), do: game
end
