defmodule PokerEx.GameEngine.CardManager do
  alias PokerEx.{Card, Deck}

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
    {:ok, update_state(cards, [:shuffle, {:deal_players, players}])}
  end

  def deal(%{cards: cards}, :flop) do
    {:ok, update_state(cards, [:deal_table, :deal_table, :deal_table])}
  end

  def deal(%{cards: cards}, phase) when phase in [:turn, :river] do
    {:ok, update_state(cards, [:deal_table])}
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
        {:ok, update_state(cards, Stream.repeatedly(fn -> :deal_table end) |> Enum.take(5 - num))}
    end
  end

  def deal(%{cards: cards}, :game_over), do: {:ok, cards}

  def deal(%{cards: cards}, :idle), do: {:ok, cards}

  @spec fold(PokerEx.GameEngine.Impl.t(), PokerEx.Player.name()) :: result()
  def fold(%{cards: cards}, name) do
    {:ok, update_state(cards, [{:remove_player_hand, name}])}
  end

  def update_state(cards, updates) when is_list(updates) do
    Enum.reduce(updates, cards, &update(&1, &2))
  end

  defp update(:shuffle, cards) do
    %__MODULE__{cards | deck: Deck.new() |> Deck.shuffle()}
  end

  defp update({:deal_players, players}, cards) do
    {dealt, new_deck} = Deck.deal(cards.deck, length(players) * 2)

    players_with_cards =
      Enum.chunk_every(dealt, 2)
      |> Enum.zip(players)

    player_hands =
      for {hand, player} <- players_with_cards do
        %{player: player, hand: hand}
      end

    %__MODULE__{cards | deck: new_deck, player_hands: player_hands}
  end

  defp update(:deal_table, cards) do
    {[dealt], deck} = Deck.deal(cards.deck, 1)
    %__MODULE__{cards | deck: deck, table: cards.table ++ [dealt]}
  end

  defp update({:remove_player_hand, name}, cards) do
    %__MODULE__{cards | player_hands: Enum.reject(cards.player_hands, &(&1.player == name))}
  end
end
