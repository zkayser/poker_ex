defmodule PokerEx.GameEngine.Seating do
  alias PokerEx.Player
  alias PokerEx.GameEngine.GameState
  @capacity 6

  @type seat_number :: 0..6 | :empty
  @type arrangement :: [{String.t(), seat_number}] | []

  @type t :: %__MODULE__{
          arrangement: arrangement
        }

  defstruct arrangement: []

  defdelegate decode(value), to: PokerEx.GameEngine.Decoders.Seating

  def new do
    %__MODULE__{}
  end

  @spec join(PokerEx.GameEngine.Impl.t(), Player.t()) :: t()
  def join(%{seating: seating}, player) do
    with true <- length(seating.arrangement) < @capacity,
         false <- player.name in Enum.map(seating.arrangement, fn {name, _pos} -> name end) do
      {:ok, GameState.update(seating, [{:insert_player, player}])}
    else
      false ->
        {:error, :room_full}

      true ->
        {:error, :already_joined}
    end
  end

  @spec leave(PokerEx.GameEngine.Impl.t(), Player.t()) :: t()
  def leave(engine, %{name: name}), do: leave(engine, name)

  @spec leave(PokerEx.GameEngine.Impl.t(), Player.name()) :: t()
  def leave(%{seating: seating}, player) do
    Map.put(
      seating,
      :arrangement,
      Enum.reject(seating.arrangement, fn {name, _} -> name == player end)
    )
  end

  @spec cycle(PokerEx.GameEngine.Impl.t()) :: t()
  def cycle(%{seating: seating}) do
    [hd | tail] = seating.arrangement
    %__MODULE__{seating | arrangement: tail ++ [hd]}
  end

  @spec is_player_seated?(PokerEx.GameEngine.Impl.t(), Player.name()) :: boolean
  def is_player_seated?(%{seating: %{arrangement: arrangement}}, player) do
    player in Enum.map(arrangement, fn {name, _} -> name end)
  end
end
