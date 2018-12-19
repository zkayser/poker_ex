defmodule PokerExWeb.NotificationsChannel do
  use Phoenix.Channel
  alias PokerEx.Player

  def join("notifications:" <> player_name, _message, socket) when is_binary(player_name) do
    case Player.by_name(player_name) do
      %Player{} -> {:ok, %{status: :ok}, socket}
      {:error, _} -> {:error, %{error: "Could not find player #{player_name}"}}
    end
  end

  def join(_, _, _) do
    raise ArgumentError,
      message: "You must pass notifications:name to join the NotificationsChannel"
  end
end
