defmodule PokerEx.GameEngine.Decoders.Hand do
  alias PokerEx.Hand
  @behaviour PokerEx.GameEngine.Decoder

  def decode("null"), do: {:ok, nil}
  def decode("\"none\""), do: {:ok, nil}

  def decode(json) do
    with {:ok, value} <- Jason.decode(json),
         {:ok, hand} <- maybe_decode_cards(value["hand"]),
         {:ok, hand_type} <- decode_hand_type(value["hand_type"]),
         {:ok, has_flush_with} <- maybe_decode_cards(value["has_flush_with"]),
         {:ok, has_straight_with} <- maybe_decode_cards(value["has_straight_with"]),
         {:ok, has_n_kind_with} <- maybe_decode_cards(value["has_n_kind_with"]),
         {:ok, best_hand} <- maybe_decode_cards(value["best_hand"]) do
      {:ok,
       %Hand{
         hand: hand,
         type_string: value["type_string"],
         hand_type: hand_type,
         score: value["score"],
         has_flush_with: has_flush_with,
         has_straight_with: has_straight_with,
         has_n_kind_with: has_n_kind_with,
         best_hand: best_hand
       }}
    else
      _ -> {:error, :decode_failed}
    end
  end

  defp maybe_decode_cards(nil), do: {:ok, nil}
  defp maybe_decode_cards(card_json), do: PokerEx.Card.decode(card_json)
  defp decode_hand_type(hand_type_json), do: {:ok, String.to_existing_atom(hand_type_json)}
end
