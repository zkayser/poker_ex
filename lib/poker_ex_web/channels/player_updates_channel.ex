defmodule PokerExWeb.PlayerUpdatesChannel do
  use Phoenix.Channel
  alias PokerEx.Player
  alias PokerEx.Repo

  def join("player_updates:" <> _player_id, _message, socket) do
    send(self(), :after_join)
    {:ok, %{}, socket}
  end

  def handle_info(:after_join, socket) do
    player = Repo.get(Player, socket.assigns.player_id)
    socket = assign(socket, :player, player)
    {:noreply, socket}
  end

  #####################
  # INCOMING MESSAGES #
  #####################

  def handle_in(event, params, socket) do
    handle_in(event, params, socket.assigns.player, socket)
  end

  def handle_in("player_update", params, player, socket) do
    unless Map.keys(params) |> Enum.all?(fn key -> key in ~w(first_name last_name email blurb chips) end) do
      {:reply, {:error, %{"error" => "Invalid attribute(s)"}}, socket}
    else
      do_handle_in("player_update", params, player, socket)
    end
  end

  def handle_in(_event, _params, _player, socket), do: {:noreply, socket}

  defp do_handle_in("player_update", %{"chips" => 1000}, player, socket) do
    if player.chips >= 100 do
      {:reply, {:error, %{message: "Cannot replenish chips unless you have less than 100 chips remaining"}}, socket}
    else
      Player.update_changeset(player, %{chips: 1000}) |> handle_player_update_response("chips", socket)
    end
  end

  defp do_handle_in("player_update", params, player, socket) do
    Player.update_changeset(player, params) |> handle_player_update_response(Map.keys(params) |> hd(), socket)
  end

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
