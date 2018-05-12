defmodule PokerEx.Hand do
  alias PokerEx.{Hand, Card}

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

  defdelegate decode(value), to: PokerEx.GameEngine.Decoders.Hand
end
