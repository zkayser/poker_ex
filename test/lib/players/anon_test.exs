defmodule PokerEx.Players.AnonTest do
  alias PokerEx.Players.Anon
  import PokerEx.TestHelpers
  use ExUnit.Case

  describe "new/1" do
    test "creates an Anon player" do
      assert {:ok, %Anon{}} = Anon.new(%{"name" => "Player: #{random_string()}"})
    end

    test "generates a guest_id for the new player" do
      assert {:ok, %Anon{guest_id: guest_id}} = Anon.new(%{"name" => "Anon user"})

      assert String.starts_with?(guest_id, "Anon user_GUEST_")
    end

    test "defaults the chip count to 1000" do
      assert {:ok, %Anon{chips: 1000}} = Anon.new(%{"name" => "Anon user"})
    end

    test "returns an error tuple if no name is given" do
      assert {:error, :missing_name} = Anon.new(%{"nombe" => "nope"})
    end

    test "returns an error if an empty string is given" do
      assert {:error, :missing_name} = Anon.new(%{"name" => ""})
    end

    test "returns an error if nil is passed for name" do
      assert {:error, :missing_name} = Anon.new(%{"name" => nil})
    end

    test "returns error if multiple white spaces are given as player name" do
      assert {:error, :missing_name} = Anon.new(%{"name" => "      \t\n"})
    end
  end

  describe "String.Chars protocol" do
    test "returns the player's name" do
      assert "name" == "#{%Anon{name: "name"}}"
    end
  end
end
