defmodule PokerEx.GameEngine.PlayerTracker do
  alias PokerEx.Player
  alias PokerEx.GameEngine.{ChipManager, GameState}
  @type tracker :: [String.t() | Player.t()] | []
  @settable_rounds [:idle, :between_rounds, :game_over]
  @type phase :: :idle | :pre_flop | :flop | :turn | :river | :game_over | :between_rounds
  @type success :: {:ok, t()}
  @type error :: {:error, :player_did_not_call | :out_of_turn}

  @type t :: %__MODULE__{
          active: tracker,
          called: tracker,
          all_in: tracker,
          folded: tracker
        }

  @derive Jason.Encoder
  defstruct active: [],
            called: [],
            all_in: [],
            folded: []

  defdelegate decode(value), to: PokerEx.GameEngine.Decoders.PlayerTracker

  def new do
    %__MODULE__{}
  end

  @spec set_active_players(PokerEx.GameEngine.Impl.t(), phase) :: PokerEx.GameEngine.Impl.t()
  def set_active_players(%{seating: seating} = engine, phase) do
    with true <- phase in @settable_rounds,
         true <- length(seating.arrangement) >= 2 do
      %{engine | player_tracker: set_active(seating.arrangement)}
    else
      _ ->
        engine
    end
  end

  @spec call(PokerEx.GameEngine.Impl.t(), Player.name(), ChipManager.t()) :: success() | error()
  def call(%{player_tracker: tracker}, name, chip_manager) do
    case get_call_state(chip_manager, name) do
      :called ->
        {:ok,
         GameState.update(tracker, [{:update_active, name, :to_back}, {:update_called, name}])}

      :all_in ->
        {:ok, GameState.update(tracker, [{:update_active, name, :drop}, {:update_all_in, name}])}

      :player_did_not_call ->
        {:error, :player_did_not_call}
    end
  end

  @spec raise(PokerEx.GameEngine.Impl.t(), Player.name(), ChipManager.t()) :: success()
  def raise(%{player_tracker: tracker}, name, chip_manager) do
    case get_raise_state(chip_manager, name) do
      {:all_in, should_clear_called?} ->
        {:ok,
         GameState.update(tracker, [
           {:update_active, name, :drop},
           {:clear_called, should_clear_called?},
           {:update_all_in, name}
         ])}

      {:raised, should_clear_called?} ->
        {:ok,
         GameState.update(tracker, [
           {:update_active, name, :to_back},
           {:clear_called, should_clear_called?},
           {:update_called_if_should_clear_is_false, should_clear_called?, name}
         ])}
    end
  end

  @spec fold(PokerEx.GameEngine.Impl.t(), Player.name()) :: success() | error()
  def fold(%{player_tracker: tracker}, name) do
    case tracker.active do
      [player | _] when player == name ->
        {:ok, GameState.update(tracker, [{:update_active, name, :drop}, {:update_folded, name}])}

      _ ->
        {:error, :out_of_turn}
    end
  end

  @spec check(PokerEx.GameEngine.Impl.t(), Player.name()) :: success() :: error()
  def check(%{player_tracker: tracker}, name) do
    case tracker.active do
      [player | _] when player == name ->
        {:ok,
         GameState.update(tracker, [{:update_active, name, :to_back}, {:update_called, name}])}

      _ ->
        {:error, :out_of_turn}
    end
  end

  @doc """
  Removes a player from the active list of players. Note that this function only
  gets called when the game engine phase is either :idle or :between_rounds. No
  poker actions (bets, etc.) take place in these rounds, so it is safe to remove
  a player without having to worry about crediting him/her with possible chips
  won later.
  """
  @spec leave(PokerEx.GameEngine.Impl.t(), Player.name()) :: success()
  def leave(%{player_tracker: tracker}, name) do
    {:ok, GameState.update(tracker, [{:update_active, name, :drop}])}
  end

  @spec is_player_active?(PokerEx.GameEngine.Impl.t(), Player.name()) :: boolean()
  def is_player_active?(%{player_tracker: %{active: active}}, player) do
    case active do
      [active_player | _] when active_player == player -> true
      _ -> false
    end
  end

  @spec cycle(PokerEx.GameEngine.Impl.t()) :: t()
  def cycle(%{player_tracker: tracker}) do
    case tracker.active do
      [] ->
        tracker

      [_] ->
        tracker

      [active | rest] ->
        %__MODULE__{tracker | active: rest ++ [active]}
    end
  end

  @spec reset_round(t()) :: t()
  def reset_round(tracker), do: %__MODULE__{tracker | called: []}

  defp set_active(arrangement) do
    %__MODULE__{active: Enum.map(arrangement, fn {name, _} -> name end)}
  end

  defp get_call_state(chip_manager, name) do
    cond do
      chip_manager.round[name] == chip_manager.to_call -> :called
      chip_manager.chip_roll[name] == 0 -> :all_in
      true -> :player_did_not_call
    end
  end

  defp get_raise_state(chip_manager, name) do
    cond do
      chip_manager.chip_roll[name] == 0 -> {:all_in, should_clear_called?(chip_manager, name)}
      true -> {:raised, should_clear_called?(chip_manager, name)}
    end
  end

  defp should_clear_called?(chip_manager, name) do
    max_paid = Enum.max(Map.values(chip_manager.round))

    case Enum.filter(Map.values(chip_manager.round), fn chip_value -> chip_value == max_paid end) do
      [max] -> chip_manager.round[name] == max
      _ -> false
    end
  end
end
