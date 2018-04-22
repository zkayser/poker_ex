defmodule PokerEx.GameEngine.Seating do
  alias PokerEx.Player
  @capacity 6

  @type seat_number :: 0..6 | :empty
  @type arrangement :: [{String.t(), non_neg_integer}] | []

  @type t :: %__MODULE__{
          arrangement: arrangement,
          active: arrangement,
          current_big_blind: seat_number,
          current_small_blind: seat_number,
          skip_advance?: boolean()
        }

  defstruct arrangement: [],
            active: [],
            current_big_blind: :empty,
            current_small_blind: :empty,
            skip_advance?: false

  def new do
    %__MODULE__{}
  end

  @spec join(PokerEx.GameEngine.Impl.t(), Player.t()) :: t()
  def join(%{seating: seating}, player) do
    with true <- length(seating.arrangement) < @capacity,
         false <- player.name in seating.arrangement do
      {:ok, insert_player(seating, player.name)}
    else
      false ->
        {:error, :room_full}

      true ->
        {:error, :already_joined}
    end
  end

  defp insert_player(%__MODULE__{arrangement: arrangement} = seating, name) do
    Map.put(seating, :arrangement, [name | arrangement])
  end
end
