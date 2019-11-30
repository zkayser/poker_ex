defmodule PokerEx.Players.BankTest do
  alias PokerEx.Players.{Anon, Bank}
  alias PokerEx.Player
  import PokerEx.TestHelpers
  use PokerEx.ModelCase

  describe "debit/2 for PokerEx.Players.Anon" do
    test "returns the updated player wrapped in an ok tuple given a valid amount" do
      assert {:ok, %Anon{chips: 800}} = Bank.debit(anon_player(), 200)
    end

    test "returns error message when debiting negative chip amounts" do
      assert {:error, "cannot debit a negative chip amount"} = Bank.debit(anon_player(), -200)
    end

    test "returns an error message when debiting more chips than the player has" do
      assert {:error, :insufficient_chips} = Bank.debit(anon_player(), 1200)
    end
  end

  describe "debit/2 for PokerEx.Player" do
    test "returns the player wrapped in an ok tuple given a valid amount" do
      assert {:ok, %Player{chips: 800}} = Bank.debit(player(), 200)
    end

    test "returns an error tuple when amount given is negative" do
      assert {:error, "cannot debit a negative chip amount"} = Bank.debit(player(), -200)
    end

    test "returns an error when debiting more chips than the player has" do
      assert {:error, :insufficient_chips} = Bank.debit(player(), 1200)
    end
  end

  describe "credit/2 for PokerEx.Players.Anon" do
    test "returns the updated player wrapped in an ok tuple given a valid amount" do
      assert {:ok, %Anon{chips: 1200}} = Bank.credit(anon_player(), 200)
    end

    test "returns an error message when crediting a negative chip amount" do
      assert {:error, "cannot credit a negative chip amount"} = Bank.credit(anon_player(), -200)
    end
  end

  describe "credit/2 for PokerEx.Player" do
    test "returns the updated player wrapped in an ok tuple given a valid amount" do
      assert {:ok, %Player{chips: 1200}} = Bank.credit(player(), 200)
    end

    test "returns an error when crediting a negative chip amount" do
      assert {:error, :negative_chip_amount} = Bank.credit(player(), -200)
    end
  end

  def player do
    insert_user()
  end

  def anon_player, do: Anon.new(%{"name" => "Anon_player:#{random_string()}"}) |> elem(1)
end
