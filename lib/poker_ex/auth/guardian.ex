defmodule PokerEx.Auth.Guardian do
  use Guardian, otp_app: :poker_ex
  alias PokerEx.{Player, Repo}

  def subject_for_resource(%Player{} = player, _options), do: {:ok, "Player:#{player.id}"}
  def subject_for_resource(_, _), do: :error

  def subject_for_token(%Player{} = player, _options), do: {:ok, "Player:#{player.id}"}
  def subject_for_token(_, _), do: :error

  def resource_from_claims("Player:" <> id), do: {:ok, Repo.get(Player, id)}
  def resource_from_claims(%{"sub" => "Player:" <> id}), do: {:ok, Repo.get(Player, id)}
  def resource_from_claims(_), do: :error
end
