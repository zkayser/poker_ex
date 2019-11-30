defimpl PokerEx.Players.Bank, for: PokerEx.Players.Anon do
  def debit(%PokerEx.Players.Anon{chips: chips} = player, amount)
      when amount <= chips and amount >= 0 do
    {:ok, %PokerEx.Players.Anon{player | chips: chips - amount}}
  end

  def debit(_player, amount) when amount < 0, do: {:error, "cannot debit a negative chip amount"}
  def debit(_player, _amount), do: {:error, :insufficient_chips}

  def credit(player, amount) when amount >= 0 do
    {:ok, %PokerEx.Players.Anon{player | chips: player.chips + amount}}
  end

  def credit(_player, _amount), do: {:error, "cannot credit a negative chip amount"}
end
