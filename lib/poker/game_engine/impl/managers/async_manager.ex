defmodule PokerEx.GameEngine.AsyncManager do
  alias PokerEx.Player
  alias PokerEx.Players.Bank
  alias PokerEx.GameEngine.{Seating, PlayerTracker, ChipManager, CardManager}

  @moduledoc """
  Handles asynchronous management of game engine state

  The PokerEx game engine encounters a number of scenarios
  where the engine state needs to be updated asynchronously
  based on certain events. Consider the following examples:

  - When a player who is an active player in an ongoing game
  decides to leave the game, the player must be removed from
  the list of active players tracked by the game. Once their
  turn comes up, the game engine needs to act on the player's
  behalf by folding. The player must then be removed from the
  game engine's seating arrangement list and their remaining
  chips from the game's chip roll must be restored to the player's
  record in the database.

  - When a player adds chips to a game during on ongoing game,
  those chips should not be added to the chip roll until the
  current game (round) finishes. Once the round finishes, the
  number of chips added by the player will be added to the
  game's chip_roll attribute in time for the next round.
  """

  @type action :: :leave | {:add_chips, pos_integer()}
  @type async_task :: :cleanup | :add_chips
  @type t() :: %__MODULE__{
          cleanup_queue: [Player.name()],
          chip_queue: [{Player.name(), pos_integer()}]
        }
  defstruct cleanup_queue: [],
            chip_queue: []

  defdelegate decode(value), to: PokerEx.GameEngine.Decoders.AsyncManager

  def new do
    %__MODULE__{}
  end

  @doc """
  Places a player in a queue for later action
  """
  @spec mark_for_action(PokerEx.GameEngine.Impl.t(), Player.name(), action) :: t()
  def mark_for_action(engine, player, :leave) do
    %__MODULE__{
      engine.async_manager
      | cleanup_queue: [player | engine.async_manager.cleanup_queue]
    }
  end

  def mark_for_action(engine, player, {:add_chips, amount}) do
    %__MODULE__{
      engine.async_manager
      | chip_queue: [{player, amount} | engine.async_manager.chip_queue]
    }
  end

  @doc """
  Updates the game engine state asynchronously given the current queues
  """
  @spec run(PokerEx.GameEngine.Impl.t(), async_task) :: PokerEx.GameEngine.Impl.t()
  def run(%{async_manager: async_manager} = engine, :cleanup) do
    Enum.reduce(async_manager.cleanup_queue, engine, &cleanup(&1, &2))
  end

  def run(%{async_manager: async_manager} = engine, :add_chips) do
    Enum.reduce(async_manager.chip_queue, engine, &add_chips(&1, &2))
  end

  defp cleanup(player, {:ok, engine}), do: cleanup(player, engine)
  defp cleanup(_player, {:error, error}), do: {:error, error}

  defp cleanup(player, engine) do
    case PlayerTracker.is_player_active?(engine, player) do
      true ->
        case ChipManager.can_player_check?(engine, player) do
          true ->
            auto_check(engine, player)

          false ->
            auto_fold(engine, player)
        end

      false ->
        {:ok, engine}
    end
  end

  defp auto_fold(engine, player) do
    with {:ok, player_tracker} = PlayerTracker.fold(engine, player),
         seating <- Seating.leave(engine, player),
         {:ok, player} <- Bank.credit(player, engine.chips.chip_roll[player.name]),
         {:ok, cards} <- CardManager.fold(engine, player),
         {:ok, chips} <- ChipManager.leave(engine, player) do
      {:ok,
       %{
         engine
         | player_tracker: player_tracker,
           seating: seating,
           chips: chips,
           cards: cards,
           async_manager: %{
             engine.async_manager
             | cleanup_queue:
                 Enum.reject(
                   engine.async_manager.cleanup_queue,
                   &(Map.get(&1, :name) == player.name)
                 )
           }
       }}
    else
      {:error, error} -> {:error, error}
      :error -> {:error, :failed_to_update}
      _ -> {:ok, engine}
    end
  end

  defp auto_check(engine, player) do
    with {:ok, player_tracker} <- PlayerTracker.check(engine, player),
         {:ok, chips} <- ChipManager.check(engine, player) do
      {:ok, %{engine | player_tracker: player_tracker, chips: chips}}
    else
      {:error, error} -> {:error, error}
      :error -> {:error, :failed_to_update}
      _ -> {:ok, engine}
    end
  end

  defp add_chips({player, amount}, {:ok, engine}), do: add_chips({player, amount}, engine)
  defp add_chips(_, {:error, error}), do: {:error, error}

  defp add_chips({player, amount}, engine) do
    case Seating.is_player_seated?(engine, player) do
      true ->
        do_add_chips(engine, player, amount)

      false ->
        engine
    end
  end

  defp do_add_chips(engine, player, amount) do
    with {:ok, player} <- Bank.debit(player, amount) do
      %{chips: chips} =
        Map.update(engine, :chips, %{}, fn chips ->
          Map.update(chips, :chip_roll, %{}, fn chip_roll ->
            Map.update(chip_roll, player.name, 0, fn old_amount -> old_amount + amount end)
          end)
        end)

      %{engine | chips: chips}
    else
      _ -> engine
    end
  end
end
