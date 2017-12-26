defmodule PokerExWeb.LobbyChannel do
	use Phoenix.Channel
	require Logger
	alias PokerEx.RoomServer
	alias PokerEx.Room

	def join("lobby:lobby", _, socket) do
		send self(), :send_rooms
		{:ok, %{response: :success}, socket}
	end

	def handle_info(:send_rooms, socket) do
		update_and_assign_rooms(socket, 1)
	end

	def handle_in("get_page", %{"page_num" => page_num}, socket) do
		update_and_assign_rooms(socket, page_num)
	end

	defp update_and_assign_rooms(socket, page_num) do
		rooms = show_rooms()
		page_num = format_page_num(page_num)
		paginated_rooms =
			rooms
				|> Scrivener.paginate(%Scrivener.Config{page_number: page_num, page_size: 10})

		Logger.debug "[LobbyChannel] Pushing `rooms` message to socket"
		push socket, "rooms",
			%{rooms: paginated_rooms.entries,
				page: page_num,
				total_pages: paginated_rooms.total_pages}
		{:noreply, socket}
	end

	defp show_rooms do
		for room <- RoomServer.get_rooms() do
			%{room: room, player_count: Room.state(room).seating |> length()}
		end
	end

	defp format_page_num(number) when is_binary(number), do: String.to_integer(number)
	defp format_page_num(number), do: number
end