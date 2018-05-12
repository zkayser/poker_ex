defmodule PokerEx.GameEngine.Decoders.Deck do
  alias PokerEx.Deck
  @behaviour PokerEx.GameEngine.Decoder

  def decode([]), do: {:ok, %Deck{}}

  def decode(json) do
    with {:ok, cards} <- PokerEx.Card.decode(json["cards"]),
         {:ok, dealt} <- PokerEx.Card.decode(json["dealt"]) do
      {:ok, %Deck{cards: cards, dealt: dealt}}
    else
      {:error, error} -> {:error, error}
    end
  end
end
