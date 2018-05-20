defimpl PokerEx.GameEngine.GameState, for: PokerEx.GameEngine.CardManager do
  alias PokerEx.Deck
  alias PokerEx.GameEngine.CardManager

  def update(cards, updates) when is_list(updates) do
    Enum.reduce(updates, cards, &do_update(&1, &2))
  end

  defp do_update(:shuffle, cards) do
    %CardManager{cards | deck: Deck.new() |> Deck.shuffle()}
  end

  defp do_update({:deal_players, players}, cards) do
    {dealt, new_deck} = Deck.deal(cards.deck, length(players) * 2)

    players_with_cards =
      Enum.chunk_every(dealt, 2)
      |> Enum.zip(players)

    player_hands =
      for {hand, player} <- players_with_cards do
        %{player: player, hand: hand}
      end

    %CardManager{cards | deck: new_deck, player_hands: player_hands}
  end

  defp do_update(:deal_table, cards) do
    {[dealt], deck} = Deck.deal(cards.deck, 1)
    %CardManager{cards | deck: deck, table: cards.table ++ [dealt]}
  end

  defp do_update({:remove_player_hand, name}, cards) do
    %CardManager{cards | player_hands: Enum.reject(cards.player_hands, &(&1.player == name))}
  end
end
