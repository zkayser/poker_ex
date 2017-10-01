defmodule PokerEx.GuardianSerializer do
  alias PokerEx.Player
  alias PokerEx.Repo

  def for_token(%Player{} = player), do: {:ok, "Player:#{player.id}"}
  def for_token(_), do: :error

  def from_token("Player:" <> id), do: {:ok, Repo.get(Player, id)}
  def from_token(_), do: :error
end
