defmodule PokerEx.GameEngine.AsyncManager do
  alias PokerEx.Player

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
  @type t() :: %__MODULE__{
          cleanup_queue: [Player.name()],
          chip_queue: [{Player.name(), pos_integer()}]
        }
  defstruct cleanup_queue: [],
            chip_queue: []

  def new do
    %__MODULE__{}
  end

  @doc """
  Places a player in a queue for later action
  """
  @spec mark_for_action(PokerEx.GameEngine.Impl.t(), Player.name(), action) :: t()
  def mark_for_action(%{player_tracker: tracker} = engine, player, :leave) do
    case player in tracker.active do
      true ->
        %__MODULE__{
          engine.async_manager
          | cleanup_queue: [player | engine.async_manager.cleanup_queue]
        }

      false ->
        engine.async_manager
    end
  end

  def mark_for_action(%{player_tracker: tracker} = engine, player, {:add_chips, amount}) do
    %__MODULE__{
      engine.async_manager
      | chip_queue: [{player, amount} | engine.async_manager.chip_queue]
    }
  end
end
