defmodule PokerEx.GameEngine.Decoders.Card do
  alias PokerEx.Card
  @behaviour PokerEx.GameEngine.Decoder

  def decode(json_list) when is_list(json_list), do: decode_list(json_list)

  def decode(json) do
    with {:ok, _} <- Jason.decode(json) do
      {:ok, %Card{rank: json["rank"], suit: json["suit"]}}
    else
      _ -> {:error, :decode_failed}
    end
  end

  defp decode_list(json) do
    Enum.reduce(json, [], fn
      _, {:error, error} ->
        {:error, error}

      card_json, {:ok, acc} ->
        card_decode(card_json, acc)

      card_json, acc ->
        card_decode(card_json, acc)
    end)
    |> maybe_reverse_list()
  end

  defp card_decode(card_json, {:ok, acc}), do: card_decode(card_json, acc)

  defp card_decode([], acc), do: {:ok, acc}

  defp card_decode(card_json, acc) do
    {:ok,
     [
       %Card{
         rank: String.to_existing_atom(card_json["rank"]),
         suit: String.to_existing_atom(card_json["suit"])
       }
       | acc
     ]}
  end

  defp maybe_reverse_list({:ok, list}), do: {:ok, Enum.reverse(list)}
  defp maybe_reverse_list([]), do: {:ok, []}

  defp maybe_reverse_list(error), do: error
end
