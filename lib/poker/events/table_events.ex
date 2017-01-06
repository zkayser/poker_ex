defmodule PokerEx.TableEvents do
  use GenEvent
  alias PokerEx.Endpoint
  
  def init([]) do
    {:ok, []}
  end
  
  def handle_event({:card_dealt, card}, state) do
    card = Enum.map(card, fn c -> Map.from_struct(c) end)
    Endpoint.broadcast("players:lobby", "card_dealt", %{card: card})
    {:ok, state}
  end
  
  def handle_event({:flop_dealt, flop}, state) do
    cards = Enum.map(flop, fn card -> Map.from_struct(card) end)
    Endpoint.broadcast("players:lobby", "flop_dealt", %{cards: cards})
    {:ok, state}
  end
  
  def handle_event({:pot_update, amount}, state) do
    Endpoint.broadcast("players:lobby", "pot_update", %{amount: amount})
    {:ok, state}
  end
  
  def handle_event({:call_amount_update, new_amount}, state) do
    Endpoint.broadcast("players:lobby", "call_amount_update", %{amount: new_amount})
    {:ok, state}
  end
  
  def handle_event({:advance, {player, _seat}}, state) do
    Endpoint.broadcast("players:lobby", "advance", %{player: player})
    {:ok, state}
  end
  
  def handle_event(_event, state), do: {:ok, state}
end