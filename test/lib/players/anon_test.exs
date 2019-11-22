defmodule PokerEx.Players.AnonTest do
  alias PokerEx.Players.Anon
  import PokerEx.TestHelpers
  use ExUnit.Case

  describe "new/1" do
    test "creates an Anon player" do
      assert {:ok, %Anon{}} = Anon.new(%{"name" => "Player: #{random_string()}"})
    end
  end
end
