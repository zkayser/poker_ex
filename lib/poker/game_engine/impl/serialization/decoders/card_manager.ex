defmodule PokerEx.GameEngine.Decoders.CardManager do
  alias PokerEx.GameEngine.CardManager
  @behaviour PokerEx.GameEngine.Decoder

  def decode(%{} = value) do
    with {:ok, deck} <- PokerEx.Deck.decode(value["deck"]),
         {:ok, table} <- PokerEx.Card.decode(value["table"]),
         {:ok, player_hands} <- decode_player_hands(value["player_hands"]) do
      {:ok, %CardManager{deck: deck, table: table, player_hands: player_hands}}
    else
      _ ->
        {:error, {:decode_failed, CardManager}}
    end
  end

  def decode(json) do
    with {:ok, value} <- Jason.decode(json),
         {:ok, deck} <- PokerEx.Deck.decode(value["deck"]),
         {:ok, table} <- PokerEx.Card.decode(value["table"]),
         {:ok, player_hands} <- decode_player_hands(value["player_hands"]) do
      {:ok, %CardManager{deck: deck, table: table, player_hands: player_hands}}
    else
      {:error, error} -> {:error, error}
    end
  end

  defp decode_player_hands(player_hands_json) do
    Enum.reduce(player_hands_json, {:ok, []}, &decode_player_hand/2)
  end

  defp decode_player_hand(player_hand, {:ok, acc}), do: decode_player_hand(player_hand, acc)

  defp decode_player_hand({:error, error}, _), do: {:error, error}

  defp decode_player_hand(%{"hand" => hand, "player" => player}, acc) do
    hand =
      for card_map <- hand do
        %PokerEx.Card{
          rank: String.to_existing_atom(card_map["rank"]),
          suit: String.to_existing_atom(card_map["suit"])
        }
      end

    {:ok, acc ++ [%{hand: hand, player: player}]}
  end
end
