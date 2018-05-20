defimpl PokerEx.GameEngine.GameState, for: PokerEx.GameEngine.ChipManager do
  alias PokerEx.GameEngine.ChipManager

  def update(chips, updates) do
    Enum.reduce(updates, chips, &do_update(&1, &2))
  end

  defp do_update({:chip_roll, player_name, amount}, chips) do
    Map.update(chips, :chip_roll, %{player_name => amount}, fn chip_roll ->
      Map.put(chip_roll, player_name, amount)
    end)
  end

  defp do_update({:set_call_amount, amount}, chips) do
    Map.put(chips, :to_call, amount)
  end

  defp do_update({:add_call_amount, name, amount}, %{round: _round} = chips) do
    adjusted_amount = ChipManager.calculate_bet_amount(amount, chips.chip_roll, name)
    raise_value = ChipManager.calculate_raise_value(name, adjusted_amount, chips)

    case raise_value > chips.to_call do
      true -> %ChipManager{chips | to_call: raise_value}
      false -> chips
    end
  end

  defp do_update(
         {:player_bet, name, amount},
         %{paid: paid, round: round, chip_roll: chip_roll, pot: pot} = chips
       ) do
    adjusted_bet = ChipManager.calculate_bet_amount(amount, chip_roll, name)

    %ChipManager{
      chips
      | pot: pot + adjusted_bet,
        paid: update_map(paid, name, adjusted_bet, :+),
        round: update_map(round, name, adjusted_bet, :+),
        chip_roll: update_map(chip_roll, name, adjusted_bet, :-)
    }
  end

  defp update_map(map, name, bet, operator) do
    Map.update(map, name, bet, fn val -> apply(Kernel, operator, [val, bet]) end)
  end
end
