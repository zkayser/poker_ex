defmodule PokerEx.GameEngine.CardManager do
  alias PokerEx.{Card, Deck}
  alias PokerEx.GameEngine.GameState

  @type t :: %__MODULE__{
          table: [Card.t()] | [],
          deck: [Card.t()] | [],
          player_hands: [%{player: String.t(), hand: [Card.t()]}]
        }
  @type success :: {:ok, t()}
  @type error :: {:error, :deal_failed}
  @type result :: success | error

  @derive Jason.Encoder
  defstruct table: [],
            deck: [],
            player_hands: []

  defdelegate decode(value), to: PokerEx.GameEngine.Decoders.CardManager

  @spec new() :: t()
  def new do
    %__MODULE__{}
  end

  @spec deal(PokerEx.GameEngine.Impl.t(), PokerEx.GameEngine.Impl.phase()) :: result()
  def deal(%{cards: cards, seating: seating}, :pre_flop) do
    players = for {player, _} <- seating.arrangement, do: player
    {:ok, GameState.update(cards, [:shuffle, {:deal_players, players}])}
  end

  def deal(%{cards: cards}, :flop) do
    {:ok, GameState.update(cards, [:deal_table, :deal_table, :deal_table])}
  end

  def deal(%{cards: cards}, phase) when phase in [:turn, :river] do
    {:ok, GameState.update(cards, [:deal_table])}
  end

  def deal(_, :between_rounds) do
    {:ok, new()}
  end

  def deal(%{cards: cards, player_tracker: %{all_in: all_in, active: active}}, :game_over)
      when length(all_in) > 0 and length(active) == 1 do
    case length(cards.table) do
      5 ->
        {:ok, cards}

      num ->
        {:ok,
         GameState.update(cards, Stream.repeatedly(fn -> :deal_table end) |> Enum.take(5 - num))}
    end
  end

  def deal(%{cards: cards}, :game_over), do: {:ok, cards}

  def deal(%{cards: cards}, :idle), do: {:ok, cards}

  @spec fold(PokerEx.GameEngine.Impl.t(), PokerEx.Player.name()) :: result()
  def fold(%{cards: cards}, name) do
    {:ok, GameState.update(cards, [{:remove_player_hand, name}])}
  end
end
