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
end