defmodule PokerEx.Evaluator do
  alias PokerEx.Card, as: Card
  alias PokerEx.Hand

  @moduledoc """
  Implements business logic for determining
  a winning hand in Hold 'Em.
  """

  @type hand :: Hand.t()

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
  @spec evaluate_hand([Card.t()], [Card.t()]) :: hand
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
    suit = for {suit, occurrences} <- suit_map, occurrences >= 5, do: suit

    case suit do
      suit when is_list(suit) and length(suit) > 0 ->
        %Hand{
          hand
          | has_flush_with: Enum.filter(hand_pool, fn card -> List.first(suit) == card.suit end)
        }

      _ ->
        hand
    end
  end

  @spec check_for_straight(hand) :: hand
  def check_for_straight(%Hand{hand: hand_pool} = hand) do
    {a_to_5?, a_to_5} = ace_to_five_straight?(hand_pool)

    straight =
      hand_pool
      |> Card.sort_by_rank()
      |> Stream.map(&Card.value/1)
      |> Stream.dedup()
      |> Stream.chunk(5, 1)
      # Adjustment for the Ace to Five straight
      |> Enum.filter(
        &(&1 == List.first(&1)..List.last(&1) |> Enum.to_list() || &1 == [14, 5, 4, 3, 2])
      )
      |> List.flatten()
      |> Enum.reverse()
      |> Enum.map(&Card.value_to_rank/1)

    case straight do
      list when length(list) >= 5 ->
        %Hand{
          hand
          | has_straight_with: Enum.filter(hand_pool, fn %Card{rank: rank} -> rank in list end)
        }

      _ ->
        if a_to_5?, do: %Hand{hand | has_straight_with: a_to_5}, else: hand
    end
  end

  @spec check_for_n_kind(hand) :: hand
  def check_for_n_kind(%Hand{hand: hand_pool} = hand) do
    n_kind =
      hand_pool
      |> Stream.map(fn %Card{rank: rank} -> rank end)
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
  defp royal_flush?(%Hand{has_flush_with: flush, has_straight_with: straight} = hand)
       when not is_nil(flush) and not is_nil(straight) do
    [%Card{suit: suit} | _] = flush

    filtered =
      straight
      |> Enum.reject(fn %Card{suit: s} -> s != suit end)
      |> Card.sort_by_rank()
      |> Enum.take(5)

    royal_flush =
      for rank <- [:ten, :jack, :queen, :king, :ace] do
        %Card{rank: rank, suit: suit}
      end

    case royal_flush |> Card.sort_by_rank() == filtered do
      true ->
        %Hand{
          hand
          | best_hand: filtered,
            hand_type: :royal_flush,
            type_string: "a ROYAL FLUSH! $$$$$",
            score: 1000
        }

      _ ->
        hand
    end
  end

  defp royal_flush?(hand), do: hand

  @spec straight_flush?(hand) :: hand
  defp straight_flush?(
         %Hand{has_flush_with: [%Card{suit: suit} | _] = flush, has_straight_with: straight} =
           hand
       )
       when not is_nil(flush) and not is_nil(straight) do
    high =
      straight
      |> Enum.filter(fn %Card{suit: s} -> s == suit end)
      |> Card.sort_by_rank()
      |> Enum.take(5)

    if high in [flush |> Card.sort_by_rank()],
      do: %Hand{
        hand
        | best_hand: high,
          hand_type: :straight_flush,
          type_string: "a Straight Flush.",
          score: 800 + rank(high)
      },
      else: hand
  end

  defp straight_flush?(hand), do: hand

  @spec four_of_a_kind?(hand) :: hand
  defp four_of_a_kind?(%Hand{has_n_kind_with: pairs} = hand) when not is_nil(pairs) do
    ranks = for %Card{rank: rank} <- pairs, do: rank

    four_kind =
      ranks
      |> Enum.reduce(%{}, fn rank, acc -> Map.update(acc, rank, 1, &(&1 + 1)) end)
      |> Enum.filter(fn {_, v} -> v == 4 end)

    if four_kind && four_kind != [] do
      [{r, _}] = four_kind
      four = Enum.filter(pairs, fn %Card{rank: rank} -> rank == r end)
      high_card = (hand.hand -- four) |> Card.sort_by_rank() |> Enum.take(1)

      %Hand{
        hand
        | best_hand: (four ++ high_card) |> Enum.sort(),
          hand_type: :four_of_a_kind,
          type_string: "Four of a Kind, #{stringify_rank(r)}s",
          score: 700 + rank(four ++ high_card)
      }
    else
      hand
    end
  end

  defp four_of_a_kind?(hand), do: hand

  @spec full_house?(hand) :: hand
  defp full_house?(%Hand{has_n_kind_with: pairs} = hand)
       when is_list(pairs) and length(pairs) >= 5 do
    ranks = for %Card{rank: rank} <- pairs, do: rank

    full =
      ranks
      |> Enum.reduce(%{}, fn rank, acc -> Map.update(acc, rank, 1, &(&1 + 1)) end)

    full_house =
      cond do
        # If a hand of 7 has two three_of_a_kind, a full_house must be made from them
        Map.values(full) == [3, 3] ->
          Card.sort_by_rank(pairs) |> Enum.take(5)

        length(Map.values(full)) > 2 && 3 in Map.values(full) ->
          {r, _} = Enum.find_value(full, fn {_, v} -> v == 3 end)
          {rs, _} = Enum.find_value(full, fn {_, v} -> v == 2 end)
          r ++ (Card.sort_by_rank(rs) |> Enum.take(2))

        length(Map.values(full)) == 2 && 3 in Map.values(full) ->
          pairs

        true ->
          nil
      end

    if full_house do
      %Hand{
        hand
        | best_hand: full_house,
          hand_type: :full_house,
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
    best = flush |> Card.sort_by_rank() |> Enum.take(5)
    [%Card{rank: high_card}] = Enum.take(best, 1)

    high_card =
      case high_card do
        x when is_list(x) -> hd(x)
        x -> x
      end

    %Hand{
      hand
      | best_hand: best,
        hand_type: :flush,
        type_string: "a Flush, #{stringify_rank(high_card)} High",
        score: 500 + Card.value(high_card)
    }
  end

  defp flush?(hand), do: hand

  @spec straight?(hand) :: hand
  defp straight?(%Hand{has_straight_with: straight} = hand)
       when is_list(straight) and length(straight) > 0 do
    best = straight |> Card.sort_by_rank() |> Enum.take(5)
    # [high_card|_tail] = best

    to =
      case List.first(best) do
        %Card{rank: :ace} ->
          case List.last(best) do
            # With an Ace to Five straight, the lowest card will be a 2 and the highest an Ace
            %{rank: :two} ->
              :five

            _ ->
              :ace
          end

        _ ->
          [%Card{rank: rank}] = Enum.take(best, 1)
          rank
      end

    to =
      case to do
        x when is_list(x) -> hd(x)
        x -> x
      end

    %Hand{
      hand
      | best_hand: best,
        hand_type: :straight,
        type_string: "a Straight, #{stringify_rank(to)} High",
        score: 400 + Card.value(to)
    }
  end

  defp straight?(hand), do: hand

  @spec three_of_a_kind?(hand) :: hand
  defp three_of_a_kind?(%Hand{has_n_kind_with: n, hand: pool} = hand)
       when is_list(n) and length(n) == 3 do
    %Card{rank: rank} = List.first(n)

    remaining =
      (pool -- n)
      |> Card.sort_by_rank()
      |> Enum.take(2)

    %Hand{
      hand
      | best_hand: (n ++ remaining) |> Card.sort_by_rank(),
        hand_type: :three_of_a_kind,
        type_string: "Three of a Kind, #{stringify_rank(rank)}s",
        score: 300 + rank(n ++ remaining)
    }
  end

  defp three_of_a_kind?(hand), do: hand

  @spec two_pair?(hand) :: hand
  defp two_pair?(%Hand{has_n_kind_with: pairs, hand: pool} = hand)
       when is_list(pairs) and rem(length(pairs), 2) == 0 and length(pairs) >= 4 do
    two_pair = Card.sort_by_rank(pairs) |> Enum.take(4)
    [%Card{rank: one}, _, %Card{rank: two}, _] = two_pair

    remaining =
      (pool -- two_pair)
      |> Card.sort_by_rank()
      |> Enum.take(1)

    %Hand{
      hand
      | best_hand: (two_pair ++ remaining) |> Enum.sort(),
        hand_type: :two_pair,
        type_string: "Two Pair, #{stringify_rank(one)}s and #{stringify_rank(two)}s",
        score: 200 + rank(two_pair ++ remaining)
    }
  end

  defp two_pair?(hand), do: hand

  @spec one_pair?(hand) :: hand
  defp one_pair?(%Hand{has_n_kind_with: pairs, hand: pool} = hand)
       when is_list(pairs) and length(pairs) == 2 do
    %Card{rank: rank} = List.first(pairs)

    remaining =
      (pool -- pairs)
      |> Card.sort_by_rank()
      |> Enum.take(3)

    %Hand{
      hand
      | best_hand: (pairs ++ remaining) |> Enum.sort(),
        hand_type: :one_pair,
        type_string: "a Pair of #{stringify_rank(rank)}s",
        score: 100 + rank(pairs ++ remaining)
    }
  end

  defp one_pair?(hand), do: hand

  @spec high_card?(hand) :: hand
  defp high_card?(
         %Hand{has_flush_with: nil, has_n_kind_with: nil, has_straight_with: nil, hand: pool} =
           hand
       ) do
    best = Card.sort_by_rank(pool) |> Enum.take(5)
    %Card{rank: rank} = List.first(best)

    %Hand{
      hand
      | best_hand: best |> Enum.sort(),
        hand_type: :high_card,
        type_string: "#{stringify_rank(rank)} High",
        score: rank(best)
    }
  end

  defp high_card?(hand), do: hand

  @spec full_house_string([Card.t()]) :: String.t()
  defp full_house_string(full_house) do
    case Enum.split(full_house, 3) do
      {[%Card{rank: one}, _, %Card{rank: two}], second} ->
        if one == two do
          "#{stringify_rank(one)}s Full of #{
            List.first(second) |> Map.get(:rank) |> stringify_rank
          }s"
        else
          "#{stringify_rank(two)}s Full of #{stringify_rank(one)}s"
        end
    end
  end

  @spec handle_n_kind_map(map, [Card.t()]) :: [Card.t()]
  defp handle_n_kind_map(n_kind, hand_pool) do
    Enum.filter(hand_pool, fn %Card{rank: rank} -> rank in Map.keys(n_kind) end)
    |> Card.sort_by_rank()
  end

  # Returns a map with the count of each suit in a hand
  @spec suit_reduce([Card.t()]) :: map
  defp suit_reduce(hand_pool) do
    suits = for %Card{suit: suit} <- hand_pool, do: suit

    suits
    |> Enum.sort()
    |> Enum.reduce(%{}, fn suit, acc -> Map.update(acc, suit, 1, &(&1 + 1)) end)
  end

  # Builds a capitalized string from a rank atom
  @spec stringify_rank(atom) :: String.t()
  defp stringify_rank(rank) do
    rank |> Atom.to_string() |> String.capitalize()
  end

  # Calculates a score based on the best hand
  @spec rank([Card.t()]) :: pos_integer
  defp rank(hand) do
    Enum.map(hand, fn card -> Card.value(card) end) |> Enum.sum()
  end

  # Determines if a hand pool includes an Ace-to-five straight
  @spec ace_to_five_straight?([Card.t()]) :: boolean()
  def ace_to_five_straight?(hand_pool) do
    ace_to_five = [:ace, :two, :three, :four, :five]
    ranks = Enum.map(hand_pool, fn %Card{rank: rank} -> rank end)
    test = ace_to_five |> Enum.all?(fn rank -> rank in ranks end)

    hand =
      Enum.map(hand_pool, fn %Card{rank: rank} = card ->
        if rank in ace_to_five do
          card
        end
      end)
      |> Enum.reject(fn val -> is_nil(val) end)

    if test, do: {true, hand}, else: {false, []}
  end
end
