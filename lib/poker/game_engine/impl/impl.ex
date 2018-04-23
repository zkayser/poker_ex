defmodule PokerEx.GameEngine.Impl do
  alias PokerEx.{Deck, Card, Player}

  alias PokerEx.GameEngine.{
    ChipManager,
    Seating,
    PlayerTracker,
    CardManager,
    ScoreManager,
    PhaseManager
  }

  alias __MODULE__, as: Engine
  @timeout 30_000
  @type t :: %Engine{
          chips: ChipManager.t(),
          seating: Seating.t(),
          type: :private | :public,
          player_tracker: PlayerTracker.t(),
          cards: CardManager.t(),
          scoring: ScoreManager.t(),
          room_id: String.t() | :none,
          timeout: pos_integer,
          phase: :idle | :pre_flop | :flop | :turn | :river | :game_over | :between_rounds
        }

  defstruct chips: ChipManager.new(),
            seating: Seating.new(),
            player_tracker: PlayerTracker.new(),
            cards: CardManager.new(),
            scoring: ScoreManager.new(),
            type: :public,
            room_id: :none,
            phase: :idle,
            timeout: @timeout

  def new do
    %Engine{}
  end

  @spec join(t(), Player.t(), non_neg_integer) :: {:ok, t()} | {:error, atom()}
  def join(engine, player, chip_amount) do
    with {:ok, new_seating} <- Seating.join(engine, player),
         {:ok, chips} <- ChipManager.join(engine, player, chip_amount) do
      {:ok,
       update_state(engine, [
         {:update_seating, new_seating},
         {:update_chips, chips},
         :maybe_change_phase,
         {:set_active_players, engine.phase}
       ])}
    else
      error -> error
    end
  end

  @spec call(t(), Player.t()) :: t()
  def call(engine, player) do
    nil
  end

  @spec raise(t(), Player.t(), non_neg_integer) :: t()
  def raise(engine, player, amount) do
    nil
  end

  @spec check(t(), Player.t()) :: t()
  def check(engine, player) do
    nil
  end

  @spec fold(t(), Player.t()) :: t()
  def fold(engine, player) do
    nil
  end

  @spec leave(t(), Player.t()) :: t()
  def leave(engine, player) do
    nil
  end

  @spec player_count(t()) :: non_neg_integer
  def player_count(engine) do
    nil
  end

  @spec player_list(t()) :: [String.t()]
  def player_list(engine) do
    nil
  end

  @spec add_chips(t(), Player.t(), pos_integer) :: t()
  def add_chips(engine, player, amount) do
    nil
  end

  defp update_state(engine, updates) do
    Enum.reduce(updates, engine, &update(&1, &2))
  end

  defp update({:update_seating, seating}, engine) do
    Map.put(engine, :seating, seating)
  end

  defp update({:update_chips, chips}, engine) do
    Map.put(engine, :chips, chips)
  end

  defp update(:maybe_change_phase, engine) do
    PhaseManager.maybe_change_phase(engine)
  end

  defp update({:set_active_players, phase}, engine) do
    PlayerTracker.set_active_players(engine, phase)
  end
end
