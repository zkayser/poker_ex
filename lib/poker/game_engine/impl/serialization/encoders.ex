defimpl Jason.Encoder, for: PokerEx.GameEngine.AsyncManager do
  alias Jason.Encode

  def encode(value, opts) do
    chip_queue =
      for {player, amount} <- value.chip_queue, into: %{} do
        {player, amount}
      end

    Encode.map(
      %{
        cleanup_queue: value.cleanup_queue,
        chip_queue: chip_queue
      },
      opts
    )
  end
end

defimpl Jason.Encoder, for: PokerEx.GameEngine.ScoreManager do
  alias Jason.Encode

  def encode(value, opts) do
    Encode.map(
      %{
        stats: encode_tuples(value.stats),
        rewards: encode_tuples(value.rewards),
        winners: encode_winners(value.winners),
        winning_hand: encode_winning_hand(value.winning_hand),
        game_id: value.game_id
      },
      opts
    )
  end

  defp encode_tuples(list_tuples) do
    for {key, value} <- list_tuples, do: %{key => value}
  end

  defp encode_winners(:none), do: "none"
  defp encode_winners(list), do: list
  defp encode_winning_hand(:none), do: "none"
  defp encode_winning_hand(hand), do: hand
end

defimpl Jason.Encoder, for: PokerEx.GameEngine.Seating do
  alias Jason.Encode

  def encode(value, opts) do
    for {player, seat_num} <- value.arrangement do
      %{player => seat_num}
    end
    |> Encode.list(opts)
  end
end
