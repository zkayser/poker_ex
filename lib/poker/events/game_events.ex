defmodule PokerEx.GameEvents do
  alias PokerEx.Endpoint
  alias PokerEx.Player
  alias PokerEx.Repo
  alias PokerEx.PlayerView
  
  def game_started(room_id, {active, _seat}, cards) do
    hands = Enum.map(cards,
      fn {name, hand} ->
        player_hand = Enum.map(hand, fn card -> Map.from_struct(card) end)
        %{player: name, hand: player_hand}
      end)
    players = Enum.map(cards, 
      fn {name, _hand} -> 
        Repo.get_by(Player, name: name)
      end)
    Endpoint.broadcast!("players:" <> room_id, "game_started", %{active: active, hands: hands} |> Map.merge(PlayerView.render("index.json", %{players: players})))
  end

  def game_over(room_id, winner, reward) do
    message = "#{winner} wins #{reward} chips"
    Endpoint.broadcast!("players:" <> room_id, "game_finished", %{message: message})
  end
  
  def winner_message(room_id, message) do
    Endpoint.broadcast!("players" <> room_id, "winner_message", %{message: message})
  end
end