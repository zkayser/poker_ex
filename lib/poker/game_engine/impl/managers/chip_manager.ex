defmodule PokerEx.GameEngine.ChipManager do
  alias PokerEx.Player
  alias PokerEx.Players.Bank
  alias PokerEx.GameEngine.GameState
  @minimum_join_amount 100
  @big_blind 10
  @small_blind 5

  @type chip_tracker :: %{(String.t() | Player.t()) => non_neg_integer} | %{}
  @type chip_roll :: %{optional(String.t()) => non_neg_integer} | %{}
  @type success :: {:ok, t()}
  @type bet_error :: {:error, :insufficient_chips | :out_of_turn | :not_paid}

  @type t :: %__MODULE__{
          to_call: non_neg_integer,
          paid: chip_tracker(),
          round: chip_tracker(),
          pot: non_neg_integer,
          chip_roll: chip_roll(),
          in_play: chip_roll()
        }

  @derive Jason.Encoder
  defstruct to_call: 0,
            paid: %{},
            round: %{},
            pot: 0,
            chip_roll: %{},
            in_play: %{}

  defdelegate decode(value), to: PokerEx.GameEngine.Decoders.ChipManager

  def new do
    %__MODULE__{}
  end

  @spec join(PokerEx.GameEngine.Impl.t(), Player.t(), pos_integer()) ::
          {:ok, t()} | {:error, atom()}
  def join(%{chips: {:ok, chips}} = engine, player, join_amount) do
    join(Map.put(engine, :chips, chips), player, join_amount)
  end

  def join(%{chips: chips}, player, join_amount)
      when join_amount >= @minimum_join_amount do
    with true <- player.chips >= join_amount,
         {:ok, player} <- Bank.debit(player, join_amount) do
      {:ok, GameState.update(chips, [{:chip_roll, player.name, join_amount}])}
    else
      false ->
        {:error, :insufficient_chips}

      error ->
        error
    end
  end

  def join(_, _, _), do: {:error, :join_amount_insufficient}

  @spec post_blinds(PokerEx.GameEngine.Impl.t()) :: success()
  def post_blinds(%{chips: chips} = engine) do
    {big_blind, small_blind} = {get_blind(engine, :big), get_blind(engine, :small)}

    {:ok,
     GameState.update(chips, [
       {:set_call_amount, @big_blind},
       {:player_bet, big_blind, @big_blind},
       {:player_bet, small_blind, @small_blind}
     ])}
  end

  @spec call(PokerEx.GameEngine.Impl.t(), Player.t()) :: success() | bet_error()
  def call(%{player_tracker: tracker, chips: chips}, player) do
    with true <- player.name == hd(tracker.active).name do
      {:ok,
       GameState.update(chips, [{:player_bet, player, calculate_call_amount(player, chips)}])}
    else
      _ ->
        {:error, :out_of_turn}
    end
  end

  @spec raise(PokerEx.GameEngine.Impl.t(), Player.t(), pos_integer) :: success() | bet_error()
  def raise(%{player_tracker: tracker, chips: chips} = engine, player, amount) do
    with true <- amount > calculate_call_amount(player, chips),
         true <- player.name == hd(tracker.active).name do
      {:ok,
       GameState.update(chips, [{:add_call_amount, player, amount}, {:player_bet, player, amount}])}
    else
      false ->
        call(engine, player)

      _ ->
        {:error, :out_of_turn}
    end
  end

  @spec check(PokerEx.GameEngine.Impl.t(), Player.t()) :: success() | bet_error()
  def check(%{player_tracker: %{active: [%{name: active_name} | _]}, chips: chips}, player) do
    case {player.name == active_name,
          chips.round[player.name] == chips.to_call || chips.to_call == 0} do
      {true, true} -> {:ok, chips}
      {false, _} -> {:error, :out_of_turn}
      {_, false} -> {:error, :not_paid}
    end
  end

  @spec leave(PokerEx.GameEngine.Impl.t(), Player.name()) :: success()
  def leave(%{chips: chips}, name) do
    {:ok,
     Map.update(chips, :chip_roll, %{}, fn chip_roll ->
       Map.drop(chip_roll, [name])
     end)}
  end

  @spec reset_round(t()) :: t()
  def reset_round(chips) do
    %__MODULE__{chips | round: %{}, to_call: 0}
  end

  @spec reset_game(t()) :: t()
  def reset_game(chips) do
    %__MODULE__{
      chips
      | round: %{},
        paid: %{},
        to_call: 0,
        pot: 0,
        chip_roll: remove_players_with_no_chips(chips.chip_roll)
    }
  end

  @spec can_player_check?(PokerEx.GameEngine.Impl.t(), Player.t()) :: boolean()
  def can_player_check?(
        %{player_tracker: %{active: active}, chips: chips},
        %{name: name} = _player
      ) do
    case active do
      [%{name: active_name} | _] when active_name == name ->
        chips.round[name] == chips.to_call || chips.to_call == 0

      _ ->
        false
    end
  end

  @spec calculate_call_amount(Player.t(), %{round: map()}) :: non_neg_integer
  def calculate_call_amount(player, %{round: round} = chips) do
    case round[player.name] do
      nil -> chips.to_call
      already_paid -> chips.to_call - already_paid
    end
  end

  defp get_blind(%{roles: _roles} = engine, :big) do
    {player, _} =
      Enum.filter(engine.seating.arrangement, fn {_, seat_num} ->
        engine.roles.big_blind == seat_num
      end)
      |> hd()

    player
  end

  defp get_blind(%{roles: _roles} = engine, :small) do
    {player, _} =
      Enum.filter(engine.seating.arrangement, fn {_, seat_num} ->
        engine.roles.small_blind == seat_num
      end)
      |> hd()

    player
  end

  defp remove_players_with_no_chips(chip_roll) do
    for {key, value} <- chip_roll, value != 0, into: %{} do
      {key, value}
    end
  end
end
