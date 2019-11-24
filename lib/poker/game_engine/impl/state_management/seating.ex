defimpl PokerEx.GameEngine.GameState, for: PokerEx.GameEngine.Seating do
  def update(seating, updates) do
    Enum.reduce(updates, seating, &do_update(&1, &2))
  end

  defp do_update({:insert_player, player}, %{arrangement: arrangement} = seating) do
    new_arrangement =
      case Enum.drop_while(0..length(arrangement), fn num ->
             num in Enum.map(arrangement, fn {_, seat_num} -> seat_num end)
           end) do
        [] ->
          insert_player_at(arrangement, player, length(arrangement))

        [head | _] ->
          insert_player_at(arrangement, player, head)
      end

    Map.put(seating, :arrangement, new_arrangement)
  end

  defp insert_player_at(arrangement, player, missing_index) do
    case Enum.find_index(arrangement, fn {_, seat_num} -> seat_num == missing_index - 1 end) do
      nil ->
        case Enum.find_index(arrangement, fn {_, seat} -> seat == missing_index + 1 end) do
          nil ->
            [{player, missing_index}] ++ arrangement

          index ->
            {front, back} = Enum.split(arrangement, index)
            front ++ [{player, missing_index}] ++ back
        end

      index ->
        {front, back} = Enum.split(arrangement, index + 1)
        front ++ [{player, missing_index}] ++ back
    end
  end
end
