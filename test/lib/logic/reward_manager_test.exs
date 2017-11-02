defmodule PokerEx.RewardManagerTest do
	use ExUnit.Case
	alias PokerEx.RewardManager, as: Manager
	
	test "creates the proper rewards list with one winner, no side pots, and no all-ins" do
		hand_rankings = [{"a", 300}, {"b", 200}, {"c", 100}]
		paid_in = [{"a", 100}, {"b", 100}, {"c", 100}, {"d", 20}]
		expected = [{"a", 320}]
		assert Manager.manage_rewards(hand_rankings, paid_in) == expected
	end
	
	test "creates the proper rewards list when hand_rankings are out of order" do
		hand_rankings = [{"2", 346}, {"3", 347}, {"1", 742}]
		paid_in = [{"1", 400}, {"2", 400}, {"3", 400}]
		expected = [{"1", 1200}]
		assert Manager.manage_rewards(hand_rankings, paid_in) == expected
	end
	
	test "creates the proper rewards list when there is a head-to-head tie" do
		hand_rankings = [{"2", 215}, {"3", 215}]
		paid_in = [{"2", 200}, {"3", 200}]
		expected = [{"2", 200}, {"3", 200}]
		assert Manager.manage_rewards(hand_rankings, paid_in) == expected
	end
	
	test "creates the proper rewards list when there is a tie with multi-players" do
		hand_rankings = [{"2", 215}, {"3", 215}, {"1", 120}, {"4", 5}]
		paid_in = [{"2", 400}, {"3", 400}, {"1", 400}, {"4", 400}]
		expected = [{"2", 800}, {"3", 800}]
		assert Manager.manage_rewards(hand_rankings, paid_in) == expected
	end
	
	test "creates the proper rewards list when there is a tie with multi-players and some all-in" do
		hand_rankings = [{"2", 215}, {"3", 215}, {"1", 120}, {"4", 5}]
		paid_in = [{"2", 100}, {"3", 200}, {"1", 200}, {"4", 50}]
		expected = [{"2", 225}, {"3", 325}]
		assert Manager.manage_rewards(hand_rankings, paid_in) == expected
	end
	
	test "creates the proper rewards list when the player with the best hand is all in and the next best 2 hands tie" do
		hand_rankings = [{"2", 300}, {"3", 200}, {"4", 200}, {"5", 10}]
		paid_in = [{"2", 50}, {"3", 200}, {"4", 200}, {"5", 100}]
		expected = [{"2", 200}, {"3", 175}, {"4", 175}]
		assert Manager.manage_rewards(hand_rankings, paid_in) == expected
	end
	
	test "creates the proper reward list with one winner, one side-pot, and the winner not all-in" do
		hand_rankings = [{"a", 300}, {"b", 200}, {"c", 100}]
		paid_in = [{"a", 100}, {"b", 50}, {"c", 100}, {"d", 20}]
		expected = [{"a", 270}]
		assert Manager.manage_rewards(hand_rankings, paid_in) == expected
	end
	
	test "creates the proper reward list when the player with the best hand is all-in and there is one side pot" do
		hand_rankings = [{"a", 300}, {"b", 200}, {"c", 100}]
		paid_in = [{"a", 100}, {"b", 200}, {"c", 200}, {"d", 50}]
		expected = [{"a", 350}, {"b", 200}]
		assert Manager.manage_rewards(hand_rankings, paid_in) == expected
	end
	
	test "creates the proper reward list when multiple players are all-in with multiple side pots" do
		hand_rankings = [{"a", 300}, {"b", 200}, {"c", 100}, {"d", 50}]
		paid_in = [{"a", 50}, {"b", 100}, {"c", 300}, {"d", 75}]
		expected = [{"a", 200}, {"b", 125},{"c", 200}]
		assert Manager.manage_rewards(hand_rankings, paid_in) == expected
	end
	
	test "creates the proper reward list when two losing players tie on an all-in with one paying in the most" do
		hand_rankings = [{"a", 136}, {"b", 133}, {"c", 133}]
		paid_in = %{"a" => 195, "b" => 200, "c" => 10, "d" => 5}
		expected = [{"a", 405}, {"b", 5}]
		assert Manager.manage_rewards(hand_rankings, paid_in) == expected
	end
end