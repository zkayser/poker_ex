defmodule PokerEx.GameEngine.Decoders.ScoreManager do
  alias PokerEx.GameEngine.ScoreManager
  @behaviour PokerEx.GameEngine.Decoder

  def decode(%{} = map), do: decode_from_map(map)

  def decode(json) do
    with {:ok, value} <- Jason.decode(json) do
      decode_from_map(value)
    else
      _ -> {:error, {:decode_failed, ScoreManager}}
    end
  end

  defp decode_from_map(value) do
    with {:ok, winning_hand_json} <- Jason.encode(value["winning_hand"]),
         {:ok, winning_hand} <- PokerEx.Hand.decode(winning_hand_json) do
      {:ok,
       %ScoreManager{
         stats: decode_to_tuples(value["stats"]),
         rewards: decode_to_tuples(value["rewards"]),
         game_id: value["game_id"],
         winning_hand: decode_winning_hand(winning_hand),
         winners: decode_winner(value["winners"])
       }}
    else
      _ ->
        {:error, :decode_failed}
    end
  end

  defp decode_to_tuples(nil), do: nil

  defp decode_to_tuples(list_maps) do
    Enum.reduce(list_maps, [], fn map, acc ->
      key = Map.keys(map) |> hd()
      [{key, map[key]} | acc]
    end)
    |> Enum.reverse()
  end

  defp decode_winning_hand(nil), do: :none
  defp decode_winning_hand(hand), do: hand
  defp decode_winner(winner) when winner in ["none", nil], do: :none
  defp decode_winner(winner), do: winner
end
