defmodule PokerEx.GameEngine.ScoreManager do
  alias PokerEx.{Player, Hand, Evaluator, RewardManager}
  @type stats :: [{String.t(), pos_integer()}] | []
  @type rewards :: [{String.t(), pos_integer()}] | []

  @type t :: %__MODULE__{
          stats: stats,
          rewards: rewards,
          winners: [String.t()] | [Player.t()] | :none,
          winning_hand: Hand.t() | :none
        }

  defstruct stats: [],
            rewards: [],
            winners: :none,
            winning_hand: :none

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
            update_state(scoring, [
              {:auto_win, engine.player_tracker.active},
              {:set_rewards, engine.chips},
              :set_winners
            ])
        end

      false ->
        update_state(scoring, [
          {:evaluate_hands, cards},
          {:set_rewards, engine.chips},
          :set_winners,
          {:set_winning_hand, cards}
        ])
    end
  end

  def update_state(scoring, updates) when is_list(updates) do
    Enum.reduce(updates, scoring, &update(&1, &2))
  end

  defp update({:evaluate_hands, cards}, scoring) do
    stats =
      Enum.map(cards.player_hands, &{&1.player, Evaluator.evaluate_hand(&1.hand, cards.table)})
      |> Enum.map(fn {player, hand} -> {player, hand.score} end)

    Map.put(scoring, :stats, stats)
  end

  defp update({:set_rewards, chips}, scoring) do
    Map.put(scoring, :rewards, RewardManager.manage_rewards(scoring.stats, chips.paid))
  end

  defp update(:set_winners, scoring) do
    {_, high_score} = Enum.max_by(scoring.stats, fn {_, score} -> score end)

    winners =
      Enum.filter(scoring.stats, fn {_, score} -> score == high_score end)
      |> Enum.map(fn {player, _} -> player end)

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
    Map.put(scoring, :stats, [{player, 1000}])
  end
end
