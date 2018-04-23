defmodule PokerEx.GameEngine.Seating do
  alias PokerEx.Player
  @capacity 6

  @type seat_number :: 0..6 | :empty
  @type arrangement :: [{String.t(), non_neg_integer}] | []

  @type t :: %__MODULE__{
          arrangement: arrangement,
          current_big_blind: {String.t(), seat_number},
          current_small_blind: {String.t(), seat_number},
          skip_advance?: boolean()
        }

  defstruct arrangement: [],
            current_big_blind: :empty,
            current_small_blind: :empty,
            skip_advance?: false

  def new do
    %__MODULE__{}
  end

  @spec join(PokerEx.GameEngine.Impl.t(), Player.t()) :: t()
  def join(%{seating: seating, phase: phase}, player) do
    with true <- length(seating.arrangement) < @capacity,
         false <- player.name in Enum.map(seating.arrangement, fn {name, pos} -> name end) do
      {:ok, update_state(seating, [{:insert_player, player}, {:maybe_set_blinds, phase}])}
    else
      false ->
        {:error, :room_full}

      true ->
        {:error, :already_joined}
    end
  end

  defp update_state(seating, updates) do
    Enum.reduce(updates, seating, &update(&1, &2))
  end

  defp update({:insert_player, player}, %{arrangement: arrangement} = seating) do
    Map.put(seating, :arrangement, [position_for(player.name, arrangement) | arrangement])
  end

  defp update({:maybe_set_blinds, phase}, %{arrangement: arrangement} = seating) do
    case phase in [:idle, :between_rounds] do
      true ->
        %__MODULE__{
          seating
          | current_big_blind: set_blind(arrangement, :big),
            current_small_blind: set_blind(arrangement, :small)
        }

      false ->
        seating
    end
  end

  defp position_for(name, arrangement), do: {name, length(arrangement)}

  defp set_blind(arrangement, :big) when length(arrangement) >= 1 do
    hd(arrangement)
  end

  defp set_blind([_ | tail], :small) when length(tail) >= 1 do
    hd(tail)
  end

  defp set_blind(_, _), do: :empty
end
