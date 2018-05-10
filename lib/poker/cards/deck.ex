defmodule PokerEx.Deck do
  @moduledoc """
  Provides a deck struct to keep track of a deck of cards
  along with functions for creating and handling decks.
  """
  alias PokerEx.Deck
  alias PokerEx.Card

  @type t :: %Deck{cards: [Card.t()], dealt: [Card.t()] | nil}
  @derive Jason.Encoder
  defstruct cards: nil, dealt: nil

  @doc """
  Creates a new deck.
  """
  @spec new() :: Deck.t()
  def new do
    suits = [:spades, :clubs, :diamonds, :hearts]

    ranks = [
      :two,
      :three,
      :four,
      :five,
      :six,
      :seven,
      :eight,
      :nine,
      :ten,
      :jack,
      :queen,
      :king,
      :ace
    ]

    deck =
      for suit <- suits,
          rank <- ranks do
        %Card{suit: suit, rank: rank}
      end

    %Deck{cards: deck}
  end

  @doc """
  Shuffles a deck in random order using the built-in
  shuffle function from the Enum module.
  """
  @spec shuffle(Deck.t()) :: Deck.t()
  def shuffle(%Deck{cards: cards}) do
    %Deck{cards: Enum.shuffle(cards)}
  end

  @doc """
  Deals `number` of cards from a deck

  ## Examples

  		iex> deck = Deck.new
  		iex> deck |> Deck.deal(5)
  		iex> deck.dealt
  		[%PokerEx.Card{rank: :two, suit: :spades},
  		%PokerEx.Card{rank: :three, suit: :spades},
  		%PokerEx.Card{rank: :four, suit: :spades},
  		%PokerEx.Card{rank: :five, suit: :spades},
  		%PokerEx.Card{rank: :six, suit: :spades}]

  """
  @spec deal(Deck.t(), pos_integer) :: Deck.t()
  def deal(%Deck{cards: cards, dealt: nil}, number) when number <= 52 do
    {current, remaining} = Enum.split(cards, number)
    {current, %Deck{cards: remaining, dealt: current}}
  end

  def deal(%Deck{cards: cards, dealt: dealt}, number)
      when not is_nil(dealt) and is_list(dealt) and length(dealt) > 0 and
             length(dealt) < 52 - number do
    {current, remaining} = Enum.split(cards, number)
    {current, %Deck{cards: remaining, dealt: [current | dealt]}}
  end

  def deal(_, _),
    do: raise("number must be less than or equal to the remaining number of cards in the deck")

  @doc """
  Decodes a deck from a JSON value
  """
  def decode(json) do
    with {:ok, cards} <- PokerEx.Card.decode_list(json["cards"]),
         {:ok, dealt} <- PokerEx.Card.decode_list(json["dealt"]) do
      {:ok, %Deck{cards: cards, dealt: dealt}}
    else
      {:error, error} -> {:error, error}
    end
  end
end
