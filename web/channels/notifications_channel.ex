defmodule PokerEx.NotificationsChannel do
  use Phoenix.Channel
  alias PokerEx.Player
  alias PokerEx.Repo
  alias PokerEx.Endpoint
  
  def join("notifications:" <> player_id, message, socket) do
    send(self(), {:after_join, player_id})
    {:ok, %{}, socket}
  end
  
  def handle_info({:after_join, player_id}, socket) do
    player = Repo.get(Player, socket.assigns.player_id)
    IO.puts "Notifications channel joined for Player #{player_id}"
    socket = assign(socket, :player, player)
    {:noreply, socket}
  end
end