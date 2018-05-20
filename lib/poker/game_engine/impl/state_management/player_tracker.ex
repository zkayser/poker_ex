defimpl PokerEx.GameEngine.GameState, for: PokerEx.GameEngine.PlayerTracker do
  alias PokerEx.GameEngine.PlayerTracker

  def update(tracker, updates) do
    Enum.reduce(updates, tracker, &do_update(&1, &2))
  end

  defp do_update({:update_active, name, :to_back}, %{active: active} = tracker) do
    Map.put(tracker, :active, Enum.drop(active, 1) |> Kernel.++([name]))
  end

  defp do_update({:update_active, _name, :drop}, %{active: active} = tracker) do
    Map.put(tracker, :active, Enum.drop(active, 1))
  end

  defp do_update({:update_called, name}, %{called: called} = tracker) do
    Map.put(tracker, :called, [name | called])
  end

  defp do_update(
         {:update_called_if_should_clear_is_false, false, name},
         %{called: called} = tracker
       ) do
    Map.put(tracker, :called, [name | called])
  end

  defp do_update({:update_called_if_should_clear_is_false, true, _name}, tracker), do: tracker

  defp do_update({:update_all_in, name}, %{all_in: all_in} = tracker) do
    Map.put(tracker, :all_in, [name | all_in])
  end

  defp do_update({:clear_called, true}, tracker) do
    %PlayerTracker{tracker | called: []}
  end

  defp do_update({:clear_called, false}, tracker), do: tracker

  defp do_update({:update_folded, name}, tracker) do
    %PlayerTracker{tracker | folded: [name | tracker.folded]}
  end
end
