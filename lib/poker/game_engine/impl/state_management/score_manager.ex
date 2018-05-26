defimpl PokerEx.GameEngine.GameState, for: PokerEx.GameEngine.ScoreManager do
  alias PokerEx.Events
  alias PokerEx.GameEngine.{ScoreManager, Evaluator, RewardManager}

  def update(scoring, updates) when is_list(updates) do
    Enum.reduce(updates, scoring, &do_update(&1, &2))
  end

  defp do_update({:evaluate_hands, cards}, scoring) do
    hands =
      Enum.map(cards.player_hands, &{&1.player, Evaluator.evaluate_hand(&1.hand, cards.table)})

    Map.put(scoring, :stats, Enum.map(hands, fn {player, hand} -> {player, hand.score} end))
    |> Map.put(:hands, Enum.map(hands, fn {_, hand} -> hand end))
  end

  defp do_update({:set_rewards, chips}, scoring) do
    Map.put(scoring, :rewards, RewardManager.manage_rewards(scoring.stats, chips.paid))
  end

  defp do_update(:set_winners, scoring) do
    {_, high_score} = Enum.max_by(scoring.stats, fn {_, score} -> score end)

    winners =
      Enum.filter(scoring.stats, fn {_, score} -> score == high_score end)
      |> Enum.map(fn {player, _} -> player end)

    Enum.each(winners, fn winner ->
      Events.game_over(
        scoring.game_id,
        winner,
        Enum.filter(scoring.rewards, fn {name, _} ->
          winner == name
        end)
        |> hd()
        |> elem(1)
      )
    end)

    %ScoreManager{scoring | winners: winners}
  end

  defp do_update({:set_winning_hand, cards}, scoring) do
    winning_hand =
      Enum.filter(cards.player_hands, fn data ->
        data.player == hd(scoring.winners)
      end)
      |> hd()

    %ScoreManager{scoring | winning_hand: winning_hand}
  end

  defp do_update({:auto_win, [player | _], type}, scoring) do
    message =
      case type do
        :raise -> "#{player} wins the round"
        :fold -> "#{player} wins the round on a fold"
      end

    Events.winner_message(scoring.game_id, message)
    Map.put(scoring, :stats, [{player, 1000}])
  end

  defp do_update(:send_winner_message, scoring) do
    winning_hand =
      Enum.filter(scoring.hands, fn hand ->
        {_, score} = Enum.max_by(scoring.stats, fn {_, score} -> score end)
        hand.score == score
      end)
      |> hd()

    Events.present_winning_hand(
      scoring.game_id,
      winning_hand.best_hand,
      hd(scoring.winners),
      winning_hand.type_string
    )

    %{scoring | winning_hand: winning_hand}
  end
end
