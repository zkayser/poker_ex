defmodule PokerEx.Card do
	alias PokerEx.Card

	@type t :: %Card{suit: suit | nil, rank: rank | nil}
	@type suit :: :spades | :diamonds | :hearts | :clubs
	@type rank :: :two | :three | :four | :five | :six 
								| :seven | :eight | :nine | :ten | :jack
								| :queen | :king | :ace | :joker
	@card_precedence %{two: 2, three: 3, four: 4, five: 5, six: 6,
										 seven: 7, eight: 8, nine: 9, ten: 10,
										 jack: 11, queen: 12, king: 13, ace: 14}
	@nums_to_rank Map.new(@card_precedence, fn {k, v} -> {v, k} end)
	
	defstruct suit: nil, rank: nil
	
	defimpl String.Chars, for: PokerEx.Card do
		@spec to_string(Card.t) :: String.t
		def to_string(card) do
			(Atom.to_string(card.rank) |> String.capitalize) <> " of " <> (Atom.to_string(card.suit) |> String.capitalize)
		end
	end
	
	@doc """
	Returns the numerical value of a card
	for comparison purposes.
	"""
	@spec value(Card.t) :: pos_integer
	def value(rank) when is_atom(rank), do: @card_precedence[rank]
	def value(%Card{rank: rank}), do: @card_precedence[rank] 
	
	@doc """
	Takes in an atom describing a card and
	returns a corresponding Card struct
		
	## Examples
	
			iex> PokerEx.Card.from_atom(:ace_of_spades)
			%PokerEx.Card{rank: :ace, suit: :spades}
				
	"""
	@spec from_atom(atom) :: Card.t
	def from_atom(atom) do
		[rank, suit] =
			atom
			|> Atom.to_string
			|> String.replace("_", " ")
			|> String.replace("of", "")
			|> String.split
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
	def value_to_rank(number), do: raise ArgumentError, "Card value must be between 2 and 14, but was #{number}"
	
	@doc """
	Sorts cards based on their rank
		
	## Examples
	
			iex> alias PokerEx.Card
			iex> cards = [:ten_of_hearts, :two_of_spades, :ace_of_diamonds, :ten_of_clubs, :three_of_hearts] |> Enum.map(&Card.from_atom/1)
			iex> Card.sort_by_rank(cards)
			[%PokerEx.Card{rank: :ace, suit: :diamonds}, %PokerEx.Card{rank: :ten, suit: :hearts}, %PokerEx.Card{rank: :ten, suit: :clubs},
			%PokerEx.Card{rank: :three, suit: :hearts}, %PokerEx.Card{rank: :two, suit: :spades}]
				
	"""
	@spec sort_by_rank([Card.t]) :: [Card.t]
	def sort_by_rank(hand), do: Enum.sort_by(hand, &Card.value/1, &>=/2)
end