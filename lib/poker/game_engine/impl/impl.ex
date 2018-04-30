defmodule PokerEx.GameEngine.Impl do
  alias PokerEx.{Deck, Card, Player}

  alias PokerEx.GameEngine.{
    ChipManager,
    Seating,
    PlayerTracker,
    CardManager,
    ScoreManager,
    PhaseManager,
    RoleManager,
    AsyncManager
  }

  alias __MODULE__, as: Engine
  @timeout 30_000
  @type success :: {:ok, t()}
  @type error :: {:error, atom()}
  @type result :: success | error
  @type phase :: :idle | :pre_flop | :flop | :turn | :river | :game_over | :between_rounds
  @type t :: %Engine{
          chips: ChipManager.t(),
          seating: Seating.t(),
          type: :private | :public,
          player_tracker: PlayerTracker.t(),
          cards: CardManager.t(),
          scoring: ScoreManager.t(),
          async_manager: AsyncManager.t(),
          game_id: String.t() | :none,
          roles: RoleManager.t(),
          timeout: pos_integer,
          phase: phase
        }

  defstruct chips: ChipManager.new(),
            seating: Seating.new(),
            player_tracker: PlayerTracker.new(),
            cards: CardManager.new(),
            scoring: ScoreManager.new(),
            roles: RoleManager.new(),
            async_manager: AsyncManager.new(),
            type: :public,
            game_id: :none,
            phase: :idle,
            timeout: @timeout

  def new do
    %Engine{}
  end

  @spec join(t(), Player.t(), non_neg_integer) :: result()
  def join(%{phase: initial_phase} = engine, player, chip_amount) do
    with {:ok, new_seating} <- Seating.join(engine, player),
         {:ok, chips} <- ChipManager.join(engine, player, chip_amount),
         phase <- PhaseManager.check_phase_change(engine, :join, new_seating) do
      {:ok,
       update_state(engine, [
         {:update_seating, new_seating},
         {:update_chips, chips},
         {:set_active_players, initial_phase},
         {:maybe_update_cards, initial_phase, phase},
         {:update_phase, phase},
         :set_roles,
         {:maybe_post_blinds, initial_phase, phase}
       ])}
    else
      error -> error
    end
  end

  @spec call(t(), Player.t()) :: result()
  def call(%{phase: initial_phase} = engine, %{name: player}) do
    with {:ok, chips} <- ChipManager.call(engine, player),
         {:ok, player_tracker} <- PlayerTracker.call(engine, player, chips),
         phase <- PhaseManager.check_phase_change(engine, :bet, player_tracker) do
      {:ok,
       update_state(engine, [
         {:update_chips, chips},
         {:update_tracker, player_tracker},
         {:maybe_update_cards, initial_phase, phase},
         {:update_phase, phase}
       ])}
      |> and_then(:process_async_auto_actions)
      |> and_then(:cleanup_round)
    else
      error -> error
    end
  end

  @spec raise(t(), Player.t(), non_neg_integer) :: result()
  def raise(%{phase: initial_phase} = engine, %{name: player}, amount) do
    with {:ok, chips} <- ChipManager.raise(engine, player, amount),
         {:ok, player_tracker} <- PlayerTracker.raise(engine, player, chips),
         phase <- PhaseManager.check_phase_change(engine, :bet, player_tracker) do
      {:ok,
       update_state(engine, [
         {:update_chips, chips},
         {:update_tracker, player_tracker},
         {:maybe_update_cards, initial_phase, phase},
         {:update_phase, phase}
       ])}
      |> and_then(:process_async_auto_actions)
      |> and_then(:cleanup_round)
    else
      error -> error
    end
  end

  @spec check(t(), Player.t()) :: result()
  def check(%{phase: initial_phase} = engine, %{name: player}) do
    with {:ok, chips} <- ChipManager.check(engine, player),
         {:ok, player_tracker} <- PlayerTracker.check(engine, player),
         phase <- PhaseManager.check_phase_change(engine, :bet, player_tracker) do
      {:ok,
       update_state(engine, [
         {:update_chips, chips},
         {:update_tracker, player_tracker},
         {:maybe_update_cards, initial_phase, phase},
         {:update_phase, phase}
       ])}
      |> and_then(:process_async_auto_actions)
      |> and_then(:cleanup_round)
    else
      error -> error
    end
  end

  @spec fold(t(), Player.t()) :: result()
  def fold(%{phase: initial_phase} = engine, %{name: player}) do
    with {:ok, player_tracker} <- PlayerTracker.fold(engine, player),
         phase <- PhaseManager.check_phase_change(engine, :bet, player_tracker) do
      {:ok,
       update_state(engine, [
         {:update_tracker, player_tracker},
         {:maybe_update_cards, initial_phase, phase},
         {:update_phase, phase}
       ])}
      |> and_then(:process_async_auto_actions)
      |> and_then(:cleanup_round)
    else
      error -> error
    end
  end

  @spec leave(t(), Player.t()) :: result()
  def leave(%{phase: initial_phase} = engine, %{name: player}) do
    {:ok,
     %__MODULE__{engine | async_manager: AsyncManager.mark_for_action(engine, player, :leave)}}
    |> and_then(:process_async_auto_actions)
    |> and_then(:cleanup_round)
  end

  @spec player_count(t()) :: non_neg_integer
  def player_count(engine) do
    length(engine.seating.arrangement)
  end

  @spec player_list(t()) :: [String.t()]
  def player_list(engine) do
    for {player, _} <- engine.seating.arrangement, do: player
  end

  @spec add_chips(t(), Player.t(), pos_integer) :: success()
  def add_chips(engine, player, amount) do
    {:ok,
     %__MODULE__{
       engine
       | async_manager: AsyncManager.mark_for_action(engine, player, {:add_chips, amount})
     }}
  end

  defp update_state(engine, updates) do
    Enum.reduce(updates, engine, &update(&1, &2))
  end

  defp update({:update_seating, seating}, engine) do
    Map.put(engine, :seating, seating)
  end

  defp update({:update_tracker, tracker}, engine) do
    Map.put(engine, :player_tracker, tracker)
  end

  defp update({:update_chips, chips}, engine) do
    Map.put(engine, :chips, chips)
  end

  defp update({:update_phase, phase}, engine) do
    Map.put(engine, :phase, phase)
  end

  defp update(:maybe_change_phase, engine) do
    PhaseManager.maybe_change_phase(engine)
  end

  defp update({:maybe_update_cards, old_phase, new_phase}, engine) do
    case old_phase != new_phase do
      true ->
        {:ok, cards} = CardManager.deal(engine, new_phase)
        %__MODULE__{engine | cards: cards}

      false ->
        engine
    end
  end

  defp update({:maybe_post_blinds, old_phase, :pre_flop}, engine) do
    case old_phase != :pre_flop do
      true ->
        {:ok, chips} = ChipManager.post_blinds(engine)

        Map.put(engine, :chips, chips)
        |> Map.put(:player_tracker, PlayerTracker.cycle(engine))

      false ->
        engine
    end
  end

  defp update({:maybe_post_blinds, _, _}, engine), do: engine

  defp update({:set_active_players, phase}, engine) do
    PlayerTracker.set_active_players(engine, phase)
  end

  defp update(:set_roles, %{phase: :pre_flop} = engine) do
    Map.put(engine, :roles, RoleManager.manage_roles(engine))
  end

  defp update(:set_roles, engine), do: engine

  # This function clause is triggered after successful poker betting actions
  # (call, raise, check, and fold). It removes any players that have been marked
  # to leave and updates the phase if appropriate. It is also triggered after leaves
  # to handle the case in which the leaving player is active. This will auto fold or
  # auto check for the player.
  defp and_then({:ok, %{phase: initial_phase} = engine}, :process_async_auto_actions) do
    with {:ok, engine} <- AsyncManager.run(engine, :cleanup),
         phase <- PhaseManager.check_phase_change(engine, :bet, engine.player_tracker) do
      {:ok,
       update_state(engine, [{:maybe_update_cards, initial_phase, phase}, {:update_phase, phase}])}
    else
      error -> error
    end
  end

  # This function clause will trigger any necessary cleanup after transitioning
  # from one phase to the next. If there is no phase transition, then this
  # clause is effectively a no-op.
  defp and_then({:ok, engine}, :cleanup_round) do
    {:ok, engine}
  end
end
