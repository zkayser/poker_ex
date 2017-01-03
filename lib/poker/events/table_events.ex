defmodule PokerEx.TableEvents do
  use GenEvent
  alias PokerEx.Endpoint
  
  def init([]) do
    {:ok, []}
  end
  
  def handle_event({:card_dealt, card}, state) do
    card = Map.from_struct(card)
    Endpoint.broadcast("players:lobby", "card_dealt", card)
    {:ok, state}
  end
  
  def handle_event({:flop_dealt, flop}, state) do
    cards = Enum.map(flop, fn card -> Map.from_struct(card) end)
    Endpoint.broadcast("players:lobby", "flop_dealt", cards)
    {:ok, state}
  end
  
  def handle_event({:advance, player}, state) do
    Endpoint.broadcast("players:lobby", "advance", player)
    {:ok, state}
  end
  
  def handle_event(_event, state), do: {:ok, state}
end