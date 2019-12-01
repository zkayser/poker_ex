defmodule PokerEx.GameEngine.GameEvents do
  alias PokerEx.GameEngine.Impl, as: GameEngine
  alias PokerExWeb.Endpoint

  @moduledoc """
  `GameEvents` allows consumers to subscribe to
  and receive updates from events taken over the
  course of a Poker game.
  """

  @doc """
  Subscribes the calling process to updates on
  the game passed in as the first argument.
  """
  @spec subscribe(GameEngine.t()) :: :ok | {:error, term()}
  def subscribe(%GameEngine{game_id: game_id}) do
    Endpoint.subscribe("poker_ex:#{game_id}")
  end
  def subscribe(_), do: {:error, :invalid_game}

  @doc """
  Notifies subscribers of game updates. Sends the
  game struct to the topic for the given game.
  """
  @spec notify_subscribers(GameEngine.t()) :: :ok, {:error, term()}
  def notify_subscribers(%GameEngine{game_id: game_id} = game_engine) do
    Endpoint.broadcast("poker_ex:#{game_id}", "update", game_engine)
  end
end
