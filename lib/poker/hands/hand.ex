defmodule PokerEx.Hand do
  alias PokerEx.Hand
  alias PokerEx.Card

  @type maybe_card_list :: [Card.t()] | nil
  @type t :: %Hand{
          hand: maybe_card_list,
          type_string: String.t(),
          hand_type: atom,
          score: pos_integer,
          has_flush_with: maybe_card_list,
          has_straight_with: maybe_card_list,
          has_n_kind_with: maybe_card_list,
          best_hand: maybe_card_list
        }

  @derive Jason.Encoder
  defstruct hand: nil,
            type_string: nil,
            hand_type: nil,
            score: nil,
            has_flush_with: nil,
            has_straight_with: nil,
            has_n_kind_with: nil,
            best_hand: nil

  @doc """
  Deserializes JSON values into Hand structs
  """
  @spec decode(String.t() | nil) :: {:ok, t} | {:error, :decode_failed} | nil
  def decode("null"), do: nil

  def decode(json) do
    with {:ok, value} <- Jason.decode(json),
         {:ok, hand} <- maybe_decode_cards(value["hand"]),
         {:ok, hand_type} <- decode_hand_type(value["hand_type"]),
         {:ok, has_flush_with} <- maybe_decode_cards(value["has_flush_with"]),
         {:ok, has_straight_with} <- maybe_decode_cards(value["has_straight_with"]),
         {:ok, has_n_kind_with} <- maybe_decode_cards(value["has_n_kind_with"]),
         {:ok, best_hand} <- maybe_decode_cards(value["best_hand"]) do
      {:ok,
       %__MODULE__{
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
      error ->
        IO.puts("Error is: #{inspect(error, pretty: true)}")
        {:error, :decode_failed}
    end
  end

  defp maybe_decode_cards(nil), do: {:ok, nil}
  defp maybe_decode_cards(card_json), do: Card.decode_list(card_json)
  defp decode_hand_type(hand_type_json), do: {:ok, String.to_existing_atom(hand_type_json)}
end
