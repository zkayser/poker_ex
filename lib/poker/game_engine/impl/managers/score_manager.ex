defmodule PokerEx.GameEngine.ScoreManager do
  alias PokerEx.{Player, Hand}
  alias PokerEx.GameEngine.GameState
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
        cond do
          length(engine.player_tracker.all_in) == 1 && Enum.empty?(engine.player_tracker.active) ->
            GameState.update(%{scoring | game_id: engine.game_id}, [
              {:auto_win, engine.player_tracker.all_in, :raise},
              {:set_rewards, engine.chips},
              :set_winners
            ])

          Enum.empty?(engine.player_tracker.all_in) ->
            GameState.update(%{scoring | game_id: engine.game_id}, [
              {:auto_win, engine.player_tracker.active, :fold},
              {:set_rewards, engine.chips},
              :set_winners
            ])

          true ->
            scoring
        end

      false ->
        GameState.update(%{scoring | game_id: engine.game_id}, [
          {:evaluate_hands, cards},
          {:set_rewards, engine.chips},
          :set_winners,
          {:set_winning_hand, cards},
          :send_winner_message
        ])
    end
  end
end
