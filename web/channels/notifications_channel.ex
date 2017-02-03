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
  
  #####################
  # Incoming Messages #
  #####################
  
  def handle_in(event, params, socket) do
    player = socket.assigns.player
    handle_in(event, params, player, socket)
  end
  
  def handle_in("player_update", %{"name" => name}, player, socket) do
    changeset = Player.update_changeset(player, %{name: name})
    handle_player_update_response(changeset, "name", socket)
  end
  
  def handle_in("player_update", %{"first_name" => first}, player, socket) do
    changeset = Player.update_changeset(player, %{first_name: first})
    handle_player_update_response(changeset, "first_name", socket)
  end
  
  def handle_in("player_update", %{"last_name" => last}, player, socket) do
    changeset = Player.update_changeset(player, %{last_name: last})
    handle_player_update_response(changeset, "last_name", socket)
  end
  
  def handle_in("player_update", %{"email" => email}, player, socket) do
    changeset = Player.update_changeset(player, %{email: email})
    handle_player_update_response(changeset, "email", socket)
  end
  
  def handle_in("player_update", %{"chips" => 1000}, player, socket) do
    if player.chips >= 100 do
      {:reply, {:error, %{message: "Cannot replenish chips unless you have less than 100 chips remaining"}}, socket}
    else
      changeset = Player.update_changeset(player, %{chips: 1000})
      handle_player_update_response(changeset, "chips", socket)
    end
  end
  
  # Catch all for player_update event
  def handle_in("player_update", params, _player, _socket), do: IO.puts "player_update with unknown payload: #{inspect(params)}"
  
  defp handle_player_update_response(changeset, type, socket) do
    case Repo.update(changeset) do
      {:ok, player} ->
        resp = %{update_type: type}
        atom_type = String.to_atom(type)
        {:reply, {:ok, Map.put(resp, atom_type, Map.get(player, atom_type))}, assign(socket, :player, player)}
      {:error, changeset} ->
        {:reply, {:error, changeset.errors}, socket}
    end
  end
end