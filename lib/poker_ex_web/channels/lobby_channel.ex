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
		socket = assign(socket, :rooms, show_rooms())
		paginated_rooms =
			socket.assigns[:rooms]
		 	|> Scrivener.paginate(%Scrivener.Config{page_number: 1, page_size: 10})

		Logger.debug "[LobbyChannel] Pushing rooms message to socket"
		push socket, "rooms",
			%{rooms: paginated_rooms.entries,
			  page: 1,
			  total_pages: paginated_rooms.total_pages}
		{:noreply, socket}
	end

	defp show_rooms do
		for room <- RoomServer.get_rooms() do
			%{room: room, player_count: Room.state(room).seating |> length()}
		end
	end
end