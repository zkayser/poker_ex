defmodule PokerEx.GameEngine.PlayerTracker do
  alias PokerEx.{Player, Card}
  alias PokerEx.GameEngine.ChipManager
  @type tracker :: [String.t() | Player.t()] | []
  @type hands :: [{String.t(), [Card.t()]}] | []
  @settable_rounds [:idle, :between_rounds]
  @type phase :: :idle | :pre_flop | :flop | :turn | :river | :game_over | :between_rounds
  @type success :: {:ok, t()}
  @type error :: {:error, :player_did_not_call | :player_not_active}

  @type t :: %__MODULE__{
          active: tracker,
          called: tracker,
          all_in: tracker,
          folded: tracker,
          hands: hands
        }

  defstruct active: [],
            called: [],
            all_in: [],
            folded: [],
            hands: []

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
  def call(%{player_tracker: tracker} = engine, name, chip_manager) do
    case get_call_state(chip_manager, name) do
      :called ->
        {:ok, update_state(tracker, [{:update_active, name, :to_back}, {:update_called, name}])}

      :all_in ->
        {:ok, update_state(tracker, [{:update_active, name, :drop}, {:update_all_in, name}])}

      :player_did_not_call ->
        {:error, :player_did_not_call}
    end
  end

  @spec raise(PokerEx.GameEngine.Impl.t(), Player.name(), ChipManager.t()) :: success()
  def raise(%{player_tracker: tracker}, name, chip_manager) do
    case get_raise_state(chip_manager, name) do
      :all_in ->
        {:ok,
         update_state(tracker, [
           {:update_active, name, :drop},
           :clear_called,
           {:update_all_in, name}
         ])}

      :raised ->
        {:ok,
         update_state(tracker, [
           {:update_active, name, :to_back},
           :clear_called
         ])}
    end
  end

  @spec fold(PokerEx.GameEngine.Impl.t(), Player.name()) :: success() | error()
  def fold(%{player_tracker: tracker}, name) do
    case tracker.active do
      [player | _] when player == name ->
        {:ok, update_state(tracker, [{:update_active, name, :drop}, {:update_folded, name}])}

      _ ->
        {:error, :player_not_active}
    end
  end

  @spec check(PokerEx.GameEngine.Impl.t(), Player.name()) :: success() :: error()
  def check(%{player_tracker: tracker}, name) do
    case tracker.active do
      [player | _] when player == name ->
        {:ok, update_state(tracker, [{:update_called, name}])}

      _ ->
        {:error, :player_not_active}
    end
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

  defp update_state(tracker, updates) do
    Enum.reduce(updates, tracker, &update(&1, &2))
  end

  defp update({:update_active, name, :to_back}, %{active: active} = tracker) do
    Map.put(tracker, :active, Enum.drop(active, 1) |> Kernel.++([name]))
  end

  defp update({:update_active, name, :drop}, %{active: active} = tracker) do
    Map.put(tracker, :active, Enum.drop(active, 1))
  end

  defp update({:update_called, name}, %{called: called} = tracker) do
    Map.put(tracker, :called, [name | called])
  end

  defp update({:update_all_in, name}, %{all_in: all_in} = tracker) do
    Map.put(tracker, :all_in, [name | all_in])
  end

  defp update(:clear_called, tracker) do
    %__MODULE__{tracker | called: []}
  end

  defp update({:update_folded, name}, tracker) do
    %__MODULE__{tracker | folded: [name | tracker.folded]}
  end

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
      chip_manager.chip_roll[name] == 0 -> :all_in
      true -> :raised
    end
  end
end
