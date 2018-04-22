defmodule PokerEx.GameEngine.ChipManager do
  alias PokerEx.Player
  @minimum_join_amount 100

  @type chip_tracker :: %{(String.t() | Player.t()) => non_neg_integer} | %{}
  @type chip_roll :: %{optional(String.t()) => non_neg_integer} | %{}

  @type t :: %__MODULE__{
          to_call: non_neg_integer,
          paid: chip_tracker(),
          round: chip_tracker(),
          pot: non_neg_integer,
          chip_roll: chip_roll(),
          in_play: chip_roll()
        }

  defstruct to_call: 0,
            paid: %{},
            round: %{},
            pot: 0,
            chip_roll: %{},
            in_play: %{}

  def new do
    %__MODULE__{}
  end

  @spec join(PokerEx.GameEngine.Impl.t(), Player.t(), pos_integer()) :: t()
  def join(%{chips: chips}, player, join_amount) when join_amount >= @minimum_join_amount do
    with {:ok, player} <- Player.subtract_chips(player.name, join_amount) do
      {:ok, update_state(chips, [{:chip_roll, player.name, join_amount}])}
    else
      error ->
        error
    end
  end

  def join(_, _, _), do: {:error, :join_amount_insufficient}

  defp update_state(chips, updates) do
    Enum.reduce(updates, chips, &update(&1, &2))
  end

  defp update({:chip_roll, player_name, amount}, chips) do
    Map.update(chips, :chip_roll, %{player_name => amount}, fn chip_roll ->
      Map.put(chip_roll, player_name, amount)
    end)
  end
end
