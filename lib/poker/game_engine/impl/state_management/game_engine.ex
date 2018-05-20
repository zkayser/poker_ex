defimpl PokerEx.GameEngine.GameState, for: PokerEx.GameEngine.Impl do
  alias PokerEx.GameEngine.Impl, as: Engine
  alias PokerEx.GameEngine.{CardManager, ChipManager, RoleManager, PlayerTracker}

  def update(%Engine{} = engine, updates) do
    Enum.reduce(updates, engine, &do_update(&1, &2))
  end

  defp do_update({:update_seating, seating}, engine) do
    Map.put(engine, :seating, seating)
    %Engine{engine | seating: seating}
  end

  defp do_update({:update_tracker, tracker}, engine) do
    Map.put(engine, :player_tracker, tracker)
  end

  defp do_update({:update_chips, chips}, engine) do
    Map.put(engine, :chips, chips)
  end

  defp do_update({:update_phase, phase}, engine) do
    Map.put(engine, :phase, phase)
  end

  defp do_update(:maybe_change_phase, engine) do
    PhaseManager.maybe_change_phase(engine)
  end

  defp do_update({:update_cards, cards}, engine) do
    Map.put(engine, :cards, cards)
  end

  defp do_update({:maybe_update_cards, old_phase, new_phase}, engine) do
    case old_phase != new_phase do
      true ->
        {:ok, cards} = CardManager.deal(engine, new_phase)
        %Engine{engine | cards: cards}

      false ->
        engine
    end
  end

  defp do_update({:maybe_post_blinds, old_phase, :pre_flop}, engine) do
    case old_phase != :pre_flop do
      true ->
        {:ok, chips} = ChipManager.post_blinds(engine)

        Map.put(engine, :chips, chips)
        |> Map.put(:player_tracker, PlayerTracker.cycle(engine))

      false ->
        engine
    end
  end

  defp do_update({:maybe_post_blinds, _, _}, engine), do: engine

  defp do_update({:set_active_players, phase}, engine) do
    PlayerTracker.set_active_players(engine, phase)
  end

  defp do_update(:set_roles, %{phase: :pre_flop} = engine) do
    Map.put(engine, :roles, RoleManager.manage_roles(engine))
  end

  defp do_update(:set_roles, engine), do: engine
end
