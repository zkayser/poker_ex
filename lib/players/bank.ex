defprotocol PokerEx.Players.Bank do
  @moduledoc """
  A protocol for managing a player's bank roll. It exposes
  an interface for transactions outside of the scope of a
  single round of poker. The interface allows bank roll
  handling to be agnostic of backend storage methods, such
  as whether or not a player's bank roll that is not in play
  exists in memory or in the database.
  """

  def debit(player, amount)
  def credit(player, amount)
end
