defmodule PokerEx.GameEngine.GameEventsTest do
  alias PokerEx.GameEngine.GameEvents
  alias PokerEx.GameEngine.Impl, as: GameEngine
  use ExUnit.Case

  describe "subscribe/1" do
    test "subscribes the calling process to game events for the given game" do
      assert :ok = GameEvents.subscribe(%GameEngine{game_id: "made up id"})
    end

    test "returns an error if it does not receive a valid game struct" do
      assert {:error, :invalid_game} = GameEvents.subscribe(%{game_id: "this doesn't work"})
    end
  end

  describe "notify_subscribers/1" do
    test "sends an update message with the new game struct to subscribers" do
      initial = PokerEx.GameEngine.get_state("game_1")
      :ok = GameEvents.subscribe(initial)

      updated_game = %GameEngine{initial | chips: %{pot: 150}}
      GameEvents.notify_subscribers(updated_game)

      assert_receive %{event: "update", payload: ^updated_game}
    end
  end
end
