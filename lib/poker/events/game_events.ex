defmodule PokerEx.GameEvents do
  alias PokerEx.Endpoint
  
  def game_started({active, _seat}, cards) do
    hands = Enum.map(cards,
      fn {name, hand} ->
        player_hand = Enum.map(hand, fn card -> Map.from_struct(card) end)
        %{player: name, hand: player_hand}
      end)
    Endpoint.broadcast!("players:lobby", "game_started", %{active: active, hands: hands})
  end

  def game_over(winner, reward) do
    message = "#{winner} wins #{reward} chips"
    Endpoint.broadcast!("players:lobby", "game_finished", %{message: message})
  end
  
  def winner_message(message) do
    Endpoint.broadcast!("players:lobby", "winner_message", %{message: message})
  end
end