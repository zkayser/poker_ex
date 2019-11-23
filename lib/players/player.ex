defmodule PokerEx.Players.Player do
  @moduledoc """
  This is a callback module that defines
  an interface of functions that will need
  to be called on Poker players during a game
  """

  @type player :: PokerEx.Player | PokerEx.Players.Anon

  @callback bet(player, pos_integer) :: {:ok, player()} | {:error, term()} | :error
  @callback credit(player, pos_integer) :: {:ok, player()} | {:error, term()}
end
