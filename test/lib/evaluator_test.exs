defmodule PokerEx.EvaluatorTest do
	use ExUnit.Case
	alias PokerEx.Card
	alias PokerEx.Evaluator
	doctest Evaluator
	
	# @tag :skip
	test "evaluate_hand detects a royal_flush" do
		player_hand = [:ten_of_spades, :jack_of_spades] |> Enum.map(&Card.from_atom/1)
		table = [:queen_of_spades, :four_of_hearts, :seven_of_diamonds, :king_of_spades, :ace_of_spades] |> Enum.map(&Card.from_atom/1)
		royal_flush = [:ten_of_spades, :jack_of_spades, :queen_of_spades, :king_of_spades, :ace_of_spades] |> Enum.map(&Card.from_atom/1)
		result = Evaluator.evaluate_hand(player_hand, table)
		assert result.best_hand == (royal_flush |> Card.sort_by_rank) 
		assert result.hand_type == :royal_flush
		assert result.score == 1000
	end
	
	# @tag :skip
	test "evaluate_hand detects straight flushes" do
		player_hand = [:five_of_clubs, :ten_of_diamonds] |> Enum.map(&Card.from_atom/1)
		table = [:six_of_clubs, :seven_of_clubs, :eight_of_clubs, :jack_of_hearts, :nine_of_clubs] |> Enum.map(&Card.from_atom/1)
		hand = [:five_of_clubs, :six_of_clubs, :seven_of_clubs, :eight_of_clubs, :nine_of_clubs] |> Enum.map(&Card.from_atom/1)
		result = Evaluator.evaluate_hand(player_hand, table)
		assert result.best_hand == hand |> Card.sort_by_rank
		assert result.hand_type == :straight_flush
		assert result.score == 835
	end
	
	# @tag :skip
	test "evaluate_hand detects four of a kind" do
		player_hand = [:king_of_diamonds, :king_of_spades] |> Enum.map(&Card.from_atom/1)
		table = [:two_of_hearts, :seven_of_diamonds, :king_of_hearts, :ace_of_spades, :king_of_clubs] |> Enum.map(&Card.from_atom/1)
		hand = [:king_of_clubs, :king_of_diamonds, :king_of_hearts, :king_of_spades, :ace_of_spades] |> Enum.map(&Card.from_atom/1)
		result = Evaluator.evaluate_hand(player_hand, table)
		assert result.best_hand == hand |> Enum.sort
		assert result.hand_type == :four_of_a_kind
		assert result.type_string == "Four of a Kind, Kings"
		assert result.score == 766
	end
	
	# @tag :skip
	test "evaluate_hand detects full houses" do
		player_hand = [:ten_of_diamonds, :queen_of_hearts] |> Enum.map(&Card.from_atom/1)
		table = [:ten_of_hearts, :ten_of_spades, :queen_of_spades, :queen_of_diamonds, :eight_of_diamonds] |> Enum.map(&Card.from_atom/1)
		hand = [:queen_of_hearts, :queen_of_spades, :queen_of_diamonds, :ten_of_diamonds, :ten_of_hearts] |> Enum.map(&Card.from_atom/1)
		result = Evaluator.evaluate_hand(player_hand, table)
		assert result.best_hand == hand 
		assert result.hand_type == :full_house
		assert result.type_string == "a Full House, Queens Full of Tens"
	end
	
	# @tag :skip
	test "evaluate_hand detects flushes" do
		player_hand = [:five_of_diamonds, :seven_of_diamonds] |> Enum.map(&Card.from_atom/1)
		table = [:two_of_diamonds, :ace_of_spades, :ten_of_clubs, :jack_of_diamonds, :queen_of_diamonds] |> Enum.map(&Card.from_atom/1)
		hand = [:five_of_diamonds, :seven_of_diamonds, :two_of_diamonds, :jack_of_diamonds, :queen_of_diamonds] |> Enum.map(&Card.from_atom/1)
		result = Evaluator.evaluate_hand(player_hand, table)
		assert result.best_hand == hand |> Card.sort_by_rank
		assert result.hand_type == :flush
	end		
	
	# @tag :skip
	test "evaluate_hand detects straights" do
		player_hand = [:eight_of_clubs, :nine_of_hearts] |> Enum.map(&Card.from_atom/1)
		table = [:ten_of_diamonds, :jack_of_spades, :two_of_hearts, :queen_of_clubs, :ace_of_spades] |> Enum.map(&Card.from_atom/1)
		hand = [:eight_of_clubs, :nine_of_hearts, :ten_of_diamonds, :jack_of_spades, :queen_of_clubs] |> Enum.map(&Card.from_atom/1)
		result = Evaluator.evaluate_hand(player_hand, table)
		assert result.best_hand == hand |> Card.sort_by_rank
		assert result.hand_type == :straight
	end
	
	# @tag :skip
	test "evaluate_hand detects three of a kind" do
		player_hand = [:five_of_diamonds, :five_of_hearts] |> Enum.map(&Card.from_atom/1)
		table = [:five_of_clubs, :ten_of_hearts, :queen_of_clubs, :six_of_spades, :two_of_diamonds] |> Enum.map(&Card.from_atom/1)
		hand = [:five_of_diamonds, :five_of_hearts, :five_of_clubs, :queen_of_clubs, :ten_of_hearts] |> Enum.map(&Card.from_atom/1)
		result = Evaluator.evaluate_hand(player_hand, table)
		assert result.best_hand == hand |> Card.sort_by_rank
		assert result.hand_type == :three_of_a_kind
	end
	
	# @tag :skip
	test "evaluate_hand detects two pair" do
		player_hand = [:three_of_clubs, :king_of_spades] |> Enum.map(&Card.from_atom/1)
		table = [:three_of_diamonds, :king_of_hearts, :ten_of_spades, :ten_of_diamonds, :five_of_clubs] |> Enum.map(&Card.from_atom/1)
		hand = [:king_of_hearts, :king_of_spades, :ten_of_diamonds, :ten_of_spades, :five_of_clubs] |> Enum.map(&Card.from_atom/1)
		result = Evaluator.evaluate_hand(player_hand, table)
		assert result.best_hand == hand |> Enum.sort
		assert result.hand_type == :two_pair
		assert result.type_string == "Two Pair, Kings and Tens"
	end
	
	# @tag :skip
	test "evaluate_hand detects one pair" do
		player_hand = [:king_of_diamonds, :ten_of_spades] |> Enum.map(&Card.from_atom/1)
		table = [:seven_of_clubs, :five_of_diamonds, :jack_of_hearts, :king_of_spades, :three_of_spades] |> Enum.map(&Card.from_atom/1)
		hand = [:king_of_diamonds, :king_of_spades, :jack_of_hearts, :ten_of_spades, :seven_of_clubs] |> Enum.map(&Card.from_atom/1)
		result = Evaluator.evaluate_hand(player_hand, table)
		assert result.best_hand == hand |> Enum.sort
		assert result.hand_type == :one_pair
		assert result.type_string == "a Pair of Kings"
	end
	
	# @tag :skip
	test "evaluate_hand detects high card appropriately" do
		player_hand = [:queen_of_diamonds, :nine_of_spades] |> Enum.map(&Card.from_atom/1)
		table = [:seven_of_clubs, :five_of_hearts, :three_of_spades, :two_of_diamonds, :four_of_clubs] |> Enum.map(&Card.from_atom/1)
		hand = [:queen_of_diamonds, :nine_of_spades, :seven_of_clubs, :five_of_hearts, :four_of_clubs] |> Enum.map(&Card.from_atom/1)
		result = Evaluator.evaluate_hand(player_hand, table)
		assert result.best_hand == hand |> Enum.sort
		assert result.hand_type == :high_card
		assert result.type_string == "Queen High"
	end
end