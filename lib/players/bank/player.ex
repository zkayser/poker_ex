defimpl PokerEx.Players.Bank, for: PokerEx.Player do
  def debit(%PokerEx.Player{name: name}, amount) do
    PokerEx.Player.subtract_chips(name, amount)
  end

  def credit(%PokerEx.Player{name: name}, amount) do
    PokerEx.Player.update_chips(name, amount)
  end
end
