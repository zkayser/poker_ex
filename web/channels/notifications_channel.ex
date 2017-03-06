defmodule PokerEx.NotificationsChannel do
  use Phoenix.Channel
  alias PokerEx.Player
  alias PokerEx.Repo
  alias PokerEx.PrivateRoom
  
  def join("notifications:" <> player_id, _message, socket) do
    send(self(), {:after_join, player_id})
    {:ok, %{}, socket}
  end
  
  def handle_info({:after_join, _player_id}, socket) do
    player = Repo.get(Player, socket.assigns.player_id)
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
  
  def handle_in("new_page", %{"current" => current, "get" => "back"} = params, player, socket) do
    IO.puts "Got params: #{inspect(params)}"
    player = player |> Repo.preload(:participating_rooms)
    page_num = current - 1
    pagination = Scrivener.paginate(player.participating_rooms, %Scrivener.Config{page_number: page_num, page_size: 10})
    entries = 
    pagination.entries
    |> Enum.map(
      fn private_room -> 
        %{title: private_room.title, participants: length(Repo.preload(private_room, :participants).participants), link: "/private/rooms/#{private_room.id}"}
      end)
    push(socket, "update_pages", %{entries: entries, current_page: page_num, total: pagination.total_pages})
    {:noreply, socket}
  end
  
  def handle_in("new_page", %{"current" => current, "get" => "ahead"} = params, player, socket) do
    IO.puts "Got params: #{inspect(params)}"
    player = player |> Repo.preload(:participating_rooms)
    page_num = current + 1
    pagination = Scrivener.paginate(player.participating_rooms, %Scrivener.Config{page_number: page_num, page_size: 10})
    
    case page_num > pagination.total_pages do
      true -> {:noreply, socket}
      _ ->
        entries = 
          pagination.entries
          |> Enum.map(
            fn priv_room ->
              %{
              title: priv_room.title, 
              participants: length(Repo.preload(priv_room, :participants).participants),
              link: "/private/rooms/#{priv_room.id}"
              }
            end)
      push(socket, "update_pages", %{entries: entries, current_page: page_num, total: pagination.total_pages})
      {:noreply, socket}
    end
  end
  
  def handle_in("new_page", %{"get" => page_num} = params, player, socket) do
    IO.puts "Got params: #{inspect(params)}"
    player = player |> Repo.preload(:participating_rooms)
    page_num = String.to_integer(page_num)
    pagination = Scrivener.paginate(player.participating_rooms, %Scrivener.Config{page_number: page_num, page_size: 10})
    case page_num > pagination.total_pages do
      true -> {:noreply, socket}
      _ ->
       entries = 
        pagination.entries
        |> Enum.map(
          fn priv_room ->
            %{
            title: priv_room.title,
            participants: length(Repo.preload(priv_room, :participants).participants),
            link: "/private/rooms/#{priv_room.id}"
            }
          end)
        push(socket, "update_pages", %{entries: entries, current_page: page_num, total: pagination.total_pages})
        {:noreply, socket} 
    end
  end
  
  def handle_in("decline_invitation", %{"room" => id}, player, socket) do
    private_room = Repo.get(PrivateRoom, id)
    case PrivateRoom.remove_invitee(private_room, player) do
      {:ok, _} -> 
        push(socket, "declined_invitation", %{remove: "row-#{id}"})
        {:noreply, socket}
      {:error, _} -> 
        push(socket, "decline_error", %{room: "#{private_room.title}"})
        {:noreply, socket}
    end
  end
  
  def handle_in("decline_own", %{"room" => id}, player, socket) do
    private_room = Repo.get(PrivateRoom, id)
    case PrivateRoom.stop_and_delete(private_room) do
      {:ok, _} ->
        push(socket, "room_terminated", %{remove: "owned-#{id}"})
        {:noreply, socket}
      _ ->
        push(socket, "room_terminate_error", %{room: "#{private_room.title}"})
        {:noreply, socket}
    end
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
  
  def handle_in("player_update", %{"blurb" => blurb}, player, socket) do
    changeset = Player.update_changeset(player, %{blurb: blurb})
    handle_player_update_response(changeset, "blurb", socket)
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