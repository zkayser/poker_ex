defmodule PokerEx.GameEngine.Decoder do
  alias PokerEx.GameEngine, as: Game
  @typep json :: String.t()
  @type value :: json | map() | atom()
  @type data_structure ::
          Game.AsyncManager
          | Game.CardManager
          | Game.ChipManager
          | Game.PlayerTracker
          | Game.RoleManager
          | Game.RoleManager
          | Game.ScoreManager
          | Game.Seating
          | PokerEx.Hand
          | PokerEx.Card
          | PokerEx.Deck

  @callback decode(value) :: {:ok, term} | {:error, {:decode_failed, data_structure}}
end
