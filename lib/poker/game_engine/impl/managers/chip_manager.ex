defmodule PokerEx.GameEngine.ChipManager do
  alias PokerEx.Player
  @minimum_join_amount 100
  @big_blind 10
  @small_blind 5

  @type chip_tracker :: %{(String.t() | Player.t()) => non_neg_integer} | %{}
  @type chip_roll :: %{optional(String.t()) => non_neg_integer} | %{}
  @type success :: {:ok, t()}
  @type bet_error :: {:error, :insufficient_chips | :out_of_turn}

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

  @spec join(PokerEx.GameEngine.Impl.t(), Player.t(), pos_integer()) ::
          {:ok, t()} | {:error, atom()}
  def join(%{chips: {:ok, chips}} = engine, player, join_amount) do
    join(Map.put(engine, :chips, chips), player, join_amount)
  end

  def join(%{chips: chips} = engine, player, join_amount)
      when join_amount >= @minimum_join_amount do
    with true <- player.chips >= join_amount,
         {:ok, player} <- Player.subtract_chips(player.name, join_amount) do
      {:ok, update_state(chips, [{:chip_roll, player.name, join_amount}])}
    else
      false ->
        {:error, :insufficient_chips}

      error ->
        error
    end
  end

  def join(_, _, _), do: {:error, :join_amount_insufficient}

  @spec post_blinds(PokerEx.GameEngine.Impl.t()) :: t()
  def post_blinds(%{chips: chips, seating: seating} = engine) do
    {big_blind, _} = seating.current_big_blind
    {small_blind, _} = seating.current_small_blind

    {:ok,
     update_state(chips, [
       {:set_call_amount, @big_blind},
       {:player_bet, big_blind, @big_blind},
       {:player_bet, small_blind, @small_blind}
     ])}
  end

  @spec call(PokerEx.GameEngine.Impl.t(), Player.name()) :: success() | bet_error()
  def call(%{player_tracker: tracker, chips: chips}, name) do
    with ^name <- hd(tracker.active) do
      {:ok, update_state(chips, [{:player_bet, name, calculate_call_amount(name, chips)}])}
    else
      _ ->
        {:error, :out_of_turn}
    end
  end

  @spec raise(PokerEx.GameEngine.Impl.t(), Player.name(), pos_integer) :: success() | bet_error()
  def raise(%{player_tracker: tracker, chips: chips} = engine, name, amount) do
    with true <- amount > calculate_call_amount(name, chips),
         ^name <- hd(tracker.active) do
      {:ok, update_state(chips, [{:add_call_amount, name, amount}, {:player_bet, name, amount}])}
    else
      false ->
        call(engine, name)

      _ ->
        {:error, :out_of_turn}
    end
  end

  defp update_state(chips, updates) do
    Enum.reduce(updates, chips, &update(&1, &2))
  end

  defp update({:chip_roll, player_name, amount}, chips) do
    Map.update(chips, :chip_roll, %{player_name => amount}, fn chip_roll ->
      Map.put(chip_roll, player_name, amount)
    end)
  end

  defp update({:set_call_amount, amount}, chips) do
    Map.put(chips, :to_call, amount)
  end

  defp update({:add_call_amount, name, amount}, %{round: round} = chips) do
    adjusted_amount = calculate_bet_amount(amount, chips.chip_roll, name)
    raise_value = calculate_raise_value(name, adjusted_amount, chips)

    case raise_value > chips.to_call do
      true -> %__MODULE__{chips | to_call: raise_value}
      false -> chips
    end
  end

  defp update(
         {:player_bet, name, amount},
         %{paid: paid, round: round, chip_roll: chip_roll, pot: pot} = chips
       ) do
    adjusted_bet = calculate_bet_amount(amount, chip_roll, name)

    %__MODULE__{
      chips
      | pot: pot + adjusted_bet,
        paid: update_map(paid, name, adjusted_bet, :+),
        round: update_map(round, name, adjusted_bet, :+),
        chip_roll: update_map(chip_roll, name, adjusted_bet, :-)
    }
  end

  defp calculate_bet_amount(amount, chip_roll, name) do
    case chip_roll[name] - amount >= 0 do
      true -> amount
      false -> chip_roll[name]
    end
  end

  defp calculate_call_amount(name, %{round: round} = chips) do
    case round[name] do
      nil -> chips.to_call
      already_paid -> chips.to_call - already_paid
    end
  end

  defp calculate_raise_value(name, adjusted_amount, %{round: round} = chips) do
    case round[name] do
      nil -> adjusted_amount
      already_paid -> already_paid + adjusted_amount
    end
  end

  defp update_map(map, name, bet, operator) do
    Map.update(map, name, bet, fn val -> apply(Kernel, operator, [val, bet]) end)
  end
end
