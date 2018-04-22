defmodule PokerEx.GameEngine.CardManager do
  alias PokerEx.{Card, Deck}

  @type t :: %__MODULE__{
          table: [Card.t()] | [],
          deck: [Card.t()] | []
        }

  defstruct table: [],
            deck: Deck.new() |> Deck.shuffle()

  def new do
    %__MODULE__{}
  end
end
