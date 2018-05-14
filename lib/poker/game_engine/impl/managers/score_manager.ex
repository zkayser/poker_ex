defmodule PokerEx.GameEngine.ScoreManager do
  alias PokerEx.{Player, Hand, Evaluator, RewardManager, Events}
  @type stats :: [{String.t(), pos_integer()}] | []
  @type rewards :: [{String.t(), pos_integer()}] | []

  @type t :: %__MODULE__{
          stats: stats,
          rewards: rewards,
          winners: [String.t()] | [Player.t()] | :none,
          winning_hand: Hand.t() | :none,
          hands: [Hand.t()] | :none,
          game_id: String.t()
        }

  defstruct stats: [],
            rewards: [],
            winners: :none,
            winning_hand: :none,
            hands: :none,
            game_id: nil

  defdelegate decode(value), to: PokerEx.GameEngine.Decoders.ScoreManager

  def new do
    %__MODULE__{}
  end

  @spec manage_score(PokerEx.GameEngine.Impl.t()) :: t()
  def manage_score(%{phase: phase, scoring: scoring}) when phase != :game_over do
    scoring
  end

  def manage_score(%{phase: :game_over, scoring: scoring, cards: cards} = engine) do
    case length(cards.table) < 5 do
      true ->
        case length(engine.player_tracker.all_in) > 0 do
          true ->
            scoring

          false ->
            update_state(%{scoring | game_id: engine.game_id}, [
              {:auto_win, engine.player_tracker.active},
              {:set_rewards, engine.chips},
              :set_winners
            ])
        end

      false ->
        update_state(%{scoring | game_id: engine.game_id}, [
          {:evaluate_hands, cards},
          {:set_rewards, engine.chips},
          :set_winners,
          {:set_winning_hand, cards},
          :send_winner_message
        ])
    end
  end

  def update_state(scoring, updates) when is_list(updates) do
    Enum.reduce(updates, scoring, &update(&1, &2))
  end

  defp update({:evaluate_hands, cards}, scoring) do
    hands =
      Enum.map(cards.player_hands, &{&1.player, Evaluator.evaluate_hand(&1.hand, cards.table)})

    Map.put(scoring, :stats, Enum.map(hands, fn {player, hand} -> {player, hand.score} end))
    |> Map.put(:hands, Enum.map(hands, fn {_, hand} -> hand end))
  end

  defp update({:set_rewards, chips}, scoring) do
    Map.put(scoring, :rewards, RewardManager.manage_rewards(scoring.stats, chips.paid))
  end

  defp update(:set_winners, scoring) do
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

    %__MODULE__{scoring | winners: winners}
  end

  defp update({:set_winning_hand, cards}, scoring) do
    winning_hand =
      Enum.filter(cards.player_hands, fn data ->
        data.player == hd(scoring.winners)
      end)
      |> hd()

    %__MODULE__{scoring | winning_hand: winning_hand}
  end

  defp update({:auto_win, [player | _]}, scoring) do
    Events.winner_message(scoring.game_id, "#{player} wins the round on a fold")
    Map.put(scoring, :stats, [{player, 1000}])
  end

  defp update(:send_winner_message, scoring) do
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
