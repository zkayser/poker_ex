defmodule PokerEx.GameEvents do
  use GenEvent
  alias PokerEx.Endpoint
  
  def init([]) do
    {:ok, []}
  end
  
  def handle_event({:game_started, {active, _seat}, cards}, state) do
    hands = Enum.map(cards,
      fn {name, hand} ->
        player_hand = Enum.map(hand, fn card -> Map.from_struct(card) end)
        %{player: name, hand: player_hand}
      end)
    Endpoint.broadcast!("players:lobby", "game_started", %{active: active, hands: hands})
    {:ok, state}
  end
  
  def handle_event({:game_over, winner, reward}, state) do
    message = "#{inspect(winner)} wins #{reward} chips"
    Endpoint.broadcast!("player:lobby", "game_finished", %{message: message})
    {:ok, state}
  end
  
  def handle_event(_event, state), do: {:ok, state}
end