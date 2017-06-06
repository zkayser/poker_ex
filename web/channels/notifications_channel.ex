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

  def handle_in("new_page", %{"current" => current, "get" => "back"}, player, socket) do
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

  def handle_in("new_page", %{"current" => current, "get" => "ahead"}, player, socket) do
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

  def handle_in("new_page", %{"get" => page_num}, player, socket) do
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

  def handle_in("decline_own", %{"room" => id}, _player, socket) do
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
end
