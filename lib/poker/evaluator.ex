defmodule PokerEx.Evaluator do
	alias PokerEx.Card, as: C
	alias PokerEx.Hand
	@moduledoc """
	Implements business logic for determining
	a winning hand in Hold 'Em.
	"""
	
	@type hand :: Hand.t
	
	@doc """
	Chooses the best five-card hand from a set of seven cards built from a player's hand and the hand dealt on the table.
		
	## Examples
	
			iex> alias PokerEx.Card
			iex> alias PokerEx.Evaluator
			iex> player_hand = [:queen_of_diamonds, :queen_of_hearts] |> Enum.map(&Card.from_atom/1)
			iex> table = [:two_of_clubs, :four_of_spades, :ten_of_diamonds, :ace_of_hearts, :three_of_spades] |> Enum.map(&Card.from_atom/1)
			iex> Evaluator.evaluate_hand(player_hand, table)
			%PokerEx.Hand{best_hand: [%PokerEx.Card{rank: :ace, suit: :hearts},
			%PokerEx.Card{rank: :four, suit: :spades},
			%PokerEx.Card{rank: :queen, suit: :diamonds},
			%PokerEx.Card{rank: :queen, suit: :hearts},
			%PokerEx.Card{rank: :ten, suit: :diamonds}],
			hand: [%PokerEx.Card{rank: :queen, suit: :diamonds},
			%PokerEx.Card{rank: :queen, suit: :hearts},
			%PokerEx.Card{rank: :two, suit: :clubs},
			%PokerEx.Card{rank: :four, suit: :spades},
			%PokerEx.Card{rank: :ten, suit: :diamonds},
			%PokerEx.Card{rank: :ace, suit: :hearts},
			%PokerEx.Card{rank: :three, suit: :spades}], hand_type: :one_pair,
			has_flush_with: nil,
			has_n_kind_with: [%PokerEx.Card{rank: :queen, suit: :diamonds},
			%PokerEx.Card{rank: :queen, suit: :hearts}], has_straight_with: nil,
			score: 152, type_string: "a Pair of Queens"}
											
	"""
	@spec evaluate_hand([C.t], [C.t]) :: hand
	def evaluate_hand(player_hand, table) do
		score(%Hand{hand: player_hand ++ table})
	end
	
	@spec score(hand) :: hand
	def score(hand) do
		hand
		|> check_for_flush
		|> check_for_straight
		|> check_for_n_kind
		|> check_type
	end
	
	@spec check_for_flush(hand) :: hand
	def check_for_flush(%Hand{hand: hand_pool} = hand) do
		suit_map = suit_reduce(hand_pool)
		suit = Enum.filter_map(suit_map, fn {_, v} -> v >= 5 end, fn {k, _} -> k end)
		
		case suit do
			suit when is_list(suit) and length(suit) > 0 ->
				%Hand{hand | has_flush_with: Enum.filter(hand_pool, fn card -> List.first(suit) == card.suit end)}
			_ -> 
				hand
		end
	end
	
	@spec check_for_straight(hand) :: hand
	def check_for_straight(%Hand{hand: hand_pool} = hand) do
		straight =
			hand_pool
			|> C.sort_by_rank
			|> Stream.map(&C.value/1)
			|> Stream.dedup
			|> Stream.chunk(5, 1)
			|> Enum.filter(&(&1 == (List.first(&1)..List.last(&1)) |> Enum.to_list) || &1 == [14, 5, 4, 3, 2]) # Adjustment for the Ace to Five straight
			|> List.flatten
			|> Enum.reverse
			|> Enum.map(&C.value_to_rank/1)
			
		case straight do
			list when length(list) >= 5 -> 
				%Hand{hand | has_straight_with: Enum.filter(hand_pool, fn %C{rank: rank} -> rank in list end)}
			_ -> 
				hand
		end
	end
			
	@spec check_for_n_kind(hand) :: hand
	def check_for_n_kind(%Hand{hand: hand_pool} = hand) do
		n_kind =
			hand_pool
			|> Stream.map(fn %C{rank: rank} -> rank end)
			|> Enum.reduce(%{}, fn rank, acc -> Map.update(acc, rank, 1, &(&1 + 1)) end)
			|> Enum.filter(fn {_, v} -> v > 1 end)
			|> Map.new()
		
		case n_kind do
			n_kind when is_map(n_kind) and map_size(n_kind) > 0 ->
				%Hand{hand | has_n_kind_with: handle_n_kind_map(n_kind, hand_pool)}
			_ ->
				hand
		end
	end
	
	@spec check_type(hand) :: hand
	def check_type(hand) do
		hand
		|> high_card?
		|> one_pair?
		|> two_pair?
		|> three_of_a_kind?
		|> straight?
		|> flush?
		|> full_house?
		|> four_of_a_kind?
		|> straight_flush?
		|> royal_flush?
	end
	
	@spec royal_flush?(hand) :: hand
	defp royal_flush?(%Hand{has_flush_with: flush, has_straight_with: straight} = hand) when not is_nil(flush) and not is_nil(straight) do
		[%C{suit: suit}|_] = flush
		
		filtered =
			straight
			|> Enum.reject(fn %C{suit: s} -> s != suit end)
			|> C.sort_by_rank
			|> Enum.take(5)
			
		royal_flush = 
			for rank <- [:ten, :jack, :queen, :king, :ace] do
				%C{rank: rank, suit: suit}
			end
			
		 case (royal_flush |> C.sort_by_rank) == filtered do
			true -> %Hand{hand | best_hand: filtered, hand_type: :royal_flush, type_string: "a ROYAL FLUSH! $$$$$", score: 1000}
			_ -> hand
		 end
	end
	defp royal_flush?(hand), do: hand
	
	@spec straight_flush?(hand) :: hand
	defp straight_flush?(%Hand{has_flush_with: [%C{suit: suit}|_] = flush, has_straight_with: straight} = hand) when not is_nil(flush) and not is_nil(straight) do
		high =
			straight
			|> Enum.filter(fn %C{suit: s} -> s == suit end)
			|> C.sort_by_rank
			|> Enum.take(5)
		
		if high in [(flush |> C.sort_by_rank)], do: %Hand{hand | best_hand: high, hand_type: :straight_flush, type_string: "a Straight Flush.", score: 800 + rank(high)}, else: hand
	end
	defp straight_flush?(hand), do: hand
	
	@spec four_of_a_kind?(hand) :: hand
	defp four_of_a_kind?(%Hand{has_n_kind_with: pairs} = hand) when not is_nil(pairs) do
		ranks = for %C{rank: rank} <- pairs, do: rank
		four_kind = 
			ranks
			|> Enum.reduce(%{}, fn rank, acc -> Map.update(acc, rank, 1, &(&1 + 1)) end)
			|> Enum.filter(fn {_, v} -> v == 4 end)
			
		
		if four_kind && four_kind != [] do
			[{r, _}] = four_kind
			four = Enum.filter(pairs, fn %C{rank: rank} -> rank == r end)
			high_card = ((hand.hand -- four) |> C.sort_by_rank |> Enum.take(1))
			%Hand{hand| best_hand: (four ++ high_card |> Enum.sort), 
						hand_type: :four_of_a_kind, type_string: "Four of a Kind, #{stringify_rank(r)}s",
						score: 700 + rank(four ++ high_card)
			}
		else
			hand
		end
	end
	defp four_of_a_kind?(hand), do: hand
	
	@spec full_house?(hand) :: hand
	defp full_house?(%Hand{has_n_kind_with: pairs} = hand) when is_list(pairs) and length(pairs) >= 5 do
		ranks = for %C{rank: rank} <- pairs, do: rank
		full =
			ranks
			|> Enum.reduce(%{}, fn rank, acc -> Map.update(acc, rank, 1, &(&1 + 1)) end)
		
		full_house = 
			cond do
				# If a hand of 7 has two three_of_a_kind, a full_house must be made from them
				Map.values(full) == [3, 3] -> 
					C.sort_by_rank(pairs) |> Enum.take(5)
				length(Map.values(full)) > 2 && 3 in Map.values(full)  -> 
					{r, _} =  Enum.find_value(full, fn {_, v} -> v == 3 end)
					{rs, _} = Enum.find_value(full, fn {_, v} -> v == 2 end)
					r ++ (C.sort_by_rank(rs) |> Enum.take(2))
				length(Map.values(full)) == 2 && 3 in Map.values(full) ->
					pairs
				true -> nil
			end
			
		if full_house do
			%Hand{hand | best_hand: full_house, hand_type: :full_house, 
						type_string: "a Full House, #{full_house_string(full_house)}",
						score: 600 + rank(full_house)
			}
		else
			hand
		end
	end
	defp full_house?(hand), do: hand
	
	@spec flush?(hand) :: hand
	defp flush?(%Hand{has_flush_with: flush} = hand) when is_list(flush) and length(flush) > 0 do
		best = flush |> C.sort_by_rank |> Enum.take(5)
		[%C{rank: high_card}] = Enum.take(best, 1)
		%Hand{hand | best_hand: best, hand_type: :flush, type_string: "a Flush, #{stringify_rank(high_card)} High",
					score: 500 + rank(best)
		}
	end
	defp flush?(hand), do: hand
	
	@spec straight?(hand) :: hand
	defp straight?(%Hand{has_straight_with: straight} = hand) when is_list(straight) and length(straight) > 0 do
		best = straight |> C.sort_by_rank |> Enum.take(5)
		
		to = 
			case List.first(best) do
				%C{rank: :ace} ->
				
					case List.last(best) do
						%{rank: :two} -> :five # With an Ace to Five straight, the lowest card will be a 2 and the highest an Ace
						_ -> :ace
					end
					
				_ -> 
					[%C{rank: rank}] = Enum.take(best, 1)
					rank
			end
		%Hand{hand | best_hand: best, hand_type: :straight, type_string: "a Straight, #{stringify_rank(to)} High",
					score: 400 + rank(best)
		}
	end
	defp straight?(hand), do: hand
	
	@spec three_of_a_kind?(hand) :: hand
	defp three_of_a_kind?(%Hand{has_n_kind_with: n, hand: pool} = hand) when is_list(n) and length(n) == 3 do
		%C{rank: rank} = List.first(n)
		remaining = 
			pool -- n
			|> C.sort_by_rank
			|> Enum.take(2)
			
		%Hand{hand | best_hand: (n ++ remaining |> C.sort_by_rank), hand_type: :three_of_a_kind,
				  type_string: "Three of a Kind, #{stringify_rank(rank)}s", score: 300 + rank(n ++ remaining)}
	end
	defp three_of_a_kind?(hand), do: hand
	
	@spec two_pair?(hand) :: hand
	defp two_pair?(%Hand{has_n_kind_with: pairs, hand: pool} = hand) when is_list(pairs) and rem(length(pairs), 2) == 0 and length(pairs) >= 4 do
		two_pair = C.sort_by_rank(pairs) |> Enum.take(4)
		[%C{rank: one}, _, %C{rank: two}, _] = two_pair
		remaining = 
			pool -- two_pair
			|> C.sort_by_rank
			|> Enum.take(1)
			
		%Hand{hand | best_hand: (two_pair ++ remaining |> Enum.sort), hand_type: :two_pair,
					type_string: "Two Pair, #{stringify_rank(one)}s and #{stringify_rank(two)}s",
					score: 200 + rank(two_pair ++ remaining)
		}
	end
	defp two_pair?(hand), do: hand
	
	@spec one_pair?(hand) :: hand
	defp one_pair?(%Hand{has_n_kind_with: pairs, hand: pool} = hand) when is_list(pairs) and length(pairs) == 2 do
		%C{rank: rank} = List.first(pairs)
		remaining =
			pool -- pairs
			|> C.sort_by_rank
			|> Enum.take(3)
			
		%Hand{hand | best_hand: (pairs ++ remaining |> Enum.sort), hand_type: :one_pair,
					type_string: "a Pair of #{stringify_rank(rank)}s", score: 100 + rank(pairs ++ remaining)}
	end
	defp one_pair?(hand), do: hand
	
	@spec high_card?(hand) :: hand
	defp high_card?(%Hand{has_flush_with: nil, has_n_kind_with: nil, has_straight_with: nil, hand: pool} = hand) do
		best = C.sort_by_rank(pool) |> Enum.take(5)
		%C{rank: rank} = List.first(best)
		%Hand{hand | best_hand: (best |> Enum.sort), hand_type: :high_card, type_string: "#{stringify_rank(rank)} High", score: rank(best)}
	end
	defp high_card?(hand), do: hand
	
	@spec full_house_string([Card.t]) :: String.t
	defp full_house_string(full_house) do
		case Enum.split(full_house, 3) do
			{[%C{rank: one}, _, %C{rank: two}], second} ->
				if one == two do
					"#{stringify_rank(one)}s Full of #{List.first(second) |> Map.get(:rank) |> stringify_rank}s"
				else
					"#{stringify_rank(two)}s Full of #{stringify_rank(one)}s"
				end
		end
	end
	
	@spec handle_n_kind_map(map, [Card.t]) :: [Card.t]
	defp handle_n_kind_map(n_kind, hand_pool) do
		Enum.filter(hand_pool, fn %C{rank: rank} -> rank in Map.keys(n_kind) end)
		|> C.sort_by_rank
	end
	
	# Returns a map with the count of each suit in a hand
	@spec suit_reduce([C.t]) :: map
	defp suit_reduce(hand_pool) do
		suits = for %C{suit: suit} <- hand_pool, do: suit
		suits
		|> Enum.sort
		|> Enum.reduce(%{}, fn suit, acc -> Map.update(acc, suit, 1, &(&1 + 1)) end)
	end
	
	# Builds a capitalized string from a rank atom
	@spec stringify_rank(atom) :: String.t
	defp stringify_rank(rank) do
		rank |> Atom.to_string |> String.capitalize
	end
	
	# Calculates a score based on the best hand
	@spec rank([C.t]) :: pos_integer
	defp rank(hand) do
		Enum.map(hand, fn card -> C.value(card) end) |> Enum.sum
	end
end