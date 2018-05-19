defmodule PokerEx.GameEngine.Decoders.Deck do
  alias PokerEx.Deck
  @behaviour PokerEx.GameEngine.Decoder

  def decode([]), do: {:ok, []}

  def decode(json) do
    dealt =
      case json["dealt"] do
        nil -> []
        dealt -> List.flatten(dealt)
      end

    with {:ok, cards} <- PokerEx.Card.decode(json["cards"]),
         {:ok, dealt} <- PokerEx.Card.decode(dealt) do
      {:ok, %Deck{cards: cards, dealt: dealt}}
    else
      {:error, error} -> {:error, error}
    end
  end
end
