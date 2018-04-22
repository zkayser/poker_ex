defmodule PokerEx.GameEngine.HandManager do
  alias PokerEx.{Player, Card}
  @type player_tracker :: [String.t() | Player.t()] | []
  @type hands :: [{String.t(), [Card.t()]}] | []

  @type t :: %__MODULE__{
          called: player_tracker,
          all_in: player_tracker,
          folded: player_tracker,
          hands: hands
        }

  defstruct called: [],
            all_in: [],
            folded: [],
            hands: []

  def new do
    %__MODULE__{}
  end
end
