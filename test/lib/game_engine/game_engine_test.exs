defmodule PokerEx.GameEngine.ImplTest do
  use ExUnit.Case
  use PokerEx.EngineCase
  alias PokerEx.GameEngine.Impl, as: Game

  @moduledoc """
  The number of operations you can make on an GameEngine.Impl
  is relatively limited, but are managed by sub-modules working
  together. The tests in this module more closely resemble integration
  tests in the sense that they ensure each of the sub-modules that
  carry out the work of the operations work together and exhibit
  expected behavior.
  """

  describe "calls" do
    test "players cannot call out of turn", context do
      engine = TestData.setup_multiplayer_game(context)

      # The first turn belongs to player 4 (context.p4)
      assert {:error, :out_of_turn} = Game.call(engine, context.p5)
    end
  end
end
