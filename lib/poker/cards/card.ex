defmodule PokerEx.Card do
  alias PokerEx.Card

  @type t :: %Card{suit: suit | nil, rank: rank | nil}
  @type suit :: :spades | :diamonds | :hearts | :clubs
  @type rank ::
          :two
          | :three
          | :four
          | :five
          | :six
          | :seven
          | :eight
          | :nine
          | :ten
          | :jack
          | :queen
          | :king
          | :ace
          | :joker
  @card_precedence %{
    two: 2,
    three: 3,
    four: 4,
    five: 5,
    six: 6,
    seven: 7,
    eight: 8,
    nine: 9,
    ten: 10,
    jack: 11,
    queen: 12,
    king: 13,
    ace: 14
  }
  @nums_to_rank Map.new(@card_precedence, fn {k, v} -> {v, k} end)

  @derive Jason.Encoder
  defstruct suit: nil, rank: nil

  defimpl String.Chars, for: PokerEx.Card do
    @spec to_string(Card.t()) :: String.t()
    def to_string(card) do
      (Atom.to_string(card.rank) |> String.capitalize()) <>
        " of " <> (Atom.to_string(card.suit) |> String.capitalize())
    end
  end

  @doc """
  Returns the numerical value of a card
  for comparison purposes.
  """
  @spec value(Card.t()) :: pos_integer
  def value(rank) when is_atom(rank), do: @card_precedence[rank]
  def value(%Card{rank: rank}), do: @card_precedence[rank]

  @doc """
  Takes in an atom describing a card and
  returns a corresponding Card struct

  ## Examples

  		iex> PokerEx.Card.from_atom(:ace_of_spades)
  		%PokerEx.Card{rank: :ace, suit: :spades}

  """
  @spec from_atom(atom) :: Card.t()
  def from_atom(atom) do
    [rank, suit] =
      atom
      |> Atom.to_string()
      |> String.replace("_", " ")
      |> String.replace("of", "")
      |> String.split()
      |> Enum.map(&String.to_atom/1)

    %Card{suit: suit, rank: rank}
  end

  @doc """
  Takes in an integer value from 2 to 14
  and returns the corresponding card rank

  ## Examples

  		iex> PokerEx.Card.value_to_rank(14)
  		:ace

  """
  @spec value_to_rank(pos_integer) :: rank
  def value_to_rank(number) when number >= 2 and number <= 14, do: @nums_to_rank[number]

  def value_to_rank(number),
    do: raise(ArgumentError, "Card value must be between 2 and 14, but was #{number}")

  @doc """
  Sorts cards based on their rank

  ## Examples

  		iex> alias PokerEx.Card
  		iex> cards = [:ten_of_hearts, :two_of_spades, :ace_of_diamonds, :ten_of_clubs, :three_of_hearts] |> Enum.map(&Card.from_atom/1)
  		iex> Card.sort_by_rank(cards)
  		[%PokerEx.Card{rank: :ace, suit: :diamonds}, %PokerEx.Card{rank: :ten, suit: :hearts}, %PokerEx.Card{rank: :ten, suit: :clubs},
  		%PokerEx.Card{rank: :three, suit: :hearts}, %PokerEx.Card{rank: :two, suit: :spades}]

  """
  @spec sort_by_rank([Card.t()]) :: [Card.t()]
  def sort_by_rank(hand), do: Enum.sort_by(hand, &Card.value/1, &>=/2)

  @doc """
  Decodes a card from a JSON value
  """
  def decode(json) do
    with {:ok, _} <- Jason.decode(json) do
      {:ok, %Card{rank: json["rank"], suit: json["suit"]}}
    else
      _ -> {:error, :decode_failed}
    end
  end

  @doc """
  Decodes a list of cards from a JSON value
  """
  def decode_list(json) do
    Enum.reduce(json, [], fn
      _, {:error, error} ->
        {:error, error}

      card_json, {:ok, acc} ->
        card_decode(card_json, acc)

      card_json, acc ->
        card_decode(card_json, acc)
    end)
    |> maybe_reverse_list()
  end

  defp card_decode(card_json, {:ok, acc}), do: card_decode(card_json, acc)

  defp card_decode(card_json, acc) do
    {:ok,
     [
       %Card{
         rank: String.to_existing_atom(card_json["rank"]),
         suit: String.to_existing_atom(card_json["suit"])
       }
       | acc
     ]}
  end

  defp maybe_reverse_list({:ok, list}), do: {:ok, Enum.reverse(list)}
  defp maybe_reverse_list(error), do: error
end
