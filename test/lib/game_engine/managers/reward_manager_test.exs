defmodule PokerEx.RewardManagerTest do
  use ExUnit.Case
  alias PokerEx.GameEngine.RewardManager, as: Manager

  test "creates the proper rewards list with one winner, no side pots, and no all-ins" do
    hand_rankings = [{%{name: "a"}, 300}, {%{name: "b"}, 200}, {%{name: "c"}, 100}]
    paid_in = [{"a", 100}, {"b", 100}, {"c", 100}, {"d", 20}]
    expected = [{%{name: "a"}, 320}]
    assert Manager.manage_rewards(hand_rankings, paid_in) == expected
  end

  test "creates the proper rewards list when hand_rankings are out of order" do
    hand_rankings = [{%{name: "2"}, 346}, {%{name: "3"}, 347}, {%{name: "1"}, 742}]
    paid_in = [{"1", 400}, {"2", 400}, {"3", 400}]
    expected = [{%{name: "1"}, 1200}]
    assert Manager.manage_rewards(hand_rankings, paid_in) == expected
  end

  test "creates the proper rewards list when there is a head-to-head tie" do
    hand_rankings = [{%{name: "2"}, 215}, {%{name: "3"}, 215}]
    paid_in = [{"2", 200}, {"3", 200}]
    expected = [{%{name: "2"}, 200}, {%{name: "3"}, 200}]
    assert Manager.manage_rewards(hand_rankings, paid_in) == expected
  end

  test "creates the proper rewards list when there is a tie with multi-players" do
    hand_rankings = [
      {%{name: "2"}, 215},
      {%{name: "3"}, 215},
      {%{name: "1"}, 120},
      {%{name: "4"}, 5}
    ]

    paid_in = [{"2", 400}, {"3", 400}, {"1", 400}, {"4", 400}]
    expected = [{%{name: "2"}, 800}, {%{name: "3"}, 800}]
    assert Manager.manage_rewards(hand_rankings, paid_in) == expected
  end

  test "creates the proper rewards list when there is a tie with multi-players and some all-in" do
    hand_rankings = [
      {%{name: "2"}, 215},
      {%{name: "3"}, 215},
      {%{name: "1"}, 120},
      {%{name: "4"}, 5}
    ]

    paid_in = [{"2", 100}, {"3", 200}, {"1", 200}, {"4", 50}]
    expected = [{%{name: "2"}, 225}, {%{name: "3"}, 325}]
    assert Manager.manage_rewards(hand_rankings, paid_in) == expected
  end

  test "creates the proper rewards list when the player with the best hand is all in and the next best 2 hands tie" do
    hand_rankings = [
      {%{name: "2"}, 300},
      {%{name: "3"}, 200},
      {%{name: "4"}, 200},
      {%{name: "5"}, 10}
    ]

    paid_in = [{"2", 50}, {"3", 200}, {"4", 200}, {"5", 100}]
    expected = [{%{name: "2"}, 200}, {%{name: "3"}, 175}, {%{name: "4"}, 175}]
    assert Manager.manage_rewards(hand_rankings, paid_in) == expected
  end

  test "creates the proper reward list with one winner, one side-pot, and the winner not all-in" do
    hand_rankings = [{%{name: "a"}, 300}, {%{name: "b"}, 200}, {%{name: "c"}, 100}]
    paid_in = [{"a", 100}, {"b", 50}, {"c", 100}, {"d", 20}]
    expected = [{%{name: "a"}, 270}]
    assert Manager.manage_rewards(hand_rankings, paid_in) == expected
  end

  test "creates the proper reward list when the player with the best hand is all-in and there is one side pot" do
    hand_rankings = [{%{name: "a"}, 300}, {%{name: "b"}, 200}, {%{name: "c"}, 100}]
    paid_in = [{"a", 100}, {"b", 200}, {"c", 200}, {"d", 50}]
    expected = [{%{name: "a"}, 350}, {%{name: "b"}, 200}]
    assert Manager.manage_rewards(hand_rankings, paid_in) == expected
  end

  test "creates the proper reward list when multiple players are all-in with multiple side pots" do
    hand_rankings = [
      {%{name: "a"}, 300},
      {%{name: "b"}, 200},
      {%{name: "c"}, 100},
      {%{name: "d"}, 50}
    ]

    paid_in = [{"a", 50}, {"b", 100}, {"c", 300}, {"d", 75}]
    expected = [{%{name: "a"}, 200}, {%{name: "b"}, 125}, {%{name: "c"}, 200}]
    assert Manager.manage_rewards(hand_rankings, paid_in) == expected
  end

  test "creates the proper reward list when two losing players tie on an all-in with one paying in the most" do
    hand_rankings = [{%{name: "a"}, 136}, {%{name: "b"}, 133}, {%{name: "c"}, 133}]
    paid_in = %{"a" => 195, "b" => 200, "c" => 10, "d" => 5}
    expected = [{%{name: "a"}, 405}, {%{name: "b"}, 5}]
    assert Manager.manage_rewards(hand_rankings, paid_in) == expected
  end
end
