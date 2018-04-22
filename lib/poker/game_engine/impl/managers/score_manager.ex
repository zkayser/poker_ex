defmodule PokerEx.GameEngine.ScoreManager do
  alias PokerEx.Player
  @type stats :: [{String.t(), pos_integer()}] | []
  @type rewards :: [{String.t(), pos_integer()}] | []

  @type t :: %__MODULE__{
          stats: stats,
          rewards: rewards,
          winner: String.t() | Player.t() | :none,
          winning_hand: Hand.t() | :none
        }

  defstruct stats: [],
            rewards: [],
            winner: :none,
            winning_hand: :none

  def new do
    %__MODULE__{}
  end
end
