defmodule PokerExWeb.PrivateRoomChannel do
	use Phoenix.Channel
	require Logger
	alias PokerEx.Player
	alias PokerEx.PrivateRoom

	def join("private_rooms:" <> player_name, _params, socket) do
		with %Player{} = player <- Player.by_name(player_name) |> Player.preload() do
			case player.id == socket.assigns.player_id do
				true ->
					send self(), :send_rooms
					{:ok, %{response: :success}, assign(socket, :player, player)}
				false -> {:error, %{message: "Authentication failed"}}
			end
		else _ -> {:error, %{message: "Authentication failed"}}
		end
	end

	def handle_info(:send_rooms, socket) do
		player_list = Player.player_names() |> Enum.reject(&(&1 == socket.assigns[:player].name))
		socket = assign(socket, :player_list, player_list)
		send_room_update(socket, 1, Player.preload(socket.assigns[:player]))
		send_player_list(socket, 1)
		{:noreply, socket}
	end

	def handle_in("accept_invitation", %{"player" => player_name, "room" => room_title}, socket) do
		PrivateRoom.accept_invitation(PrivateRoom.by_title(room_title), Player.by_name(player_name))
		send_room_update(socket, 1, Player.by_name(player_name) |> Player.preload())
		{:noreply, socket}
	end

	def handle_in("create_room", %{"title" => title, "owner" => owner, "invitees" => invitees}, socket) do
		owner = Player.by_name(owner)
		invitees = Enum.map(invitees, &(Player.by_name(&1)))
		case PrivateRoom.create(title, owner, invitees) do
			{:ok, %PrivateRoom{}} -> {:reply, :ok, socket}
			{:error, errors} -> {:stop, :shutdown, {:error, %{errors: format(errors)}}, socket}
		end
	end

	def handle_in("leave_room", %{"room" => title, "player" => player, "current_page" => page_num}, socket) do
		player = Player.by_name(player) |> Player.preload()
		room = PrivateRoom.by_title(title) |> PrivateRoom.preload()
		case PrivateRoom.leave_room(room, player) do
			{:ok, _} -> send_room_update(socket, page_num, player)
			{:error, _} -> push socket, "error", %{error: "Failed to leave room. Please try again."}
		end
		{:noreply, socket}
	end

	def handle_in("get_page", %{"for" => type, "page_num" => page_num}, socket) do
		params =
			case type do
				"current_rooms" ->
					page_struct = get_paginated_rooms(socket.assigns[:player], page_num, :participating_rooms)
					%{current_rooms: %{
						rooms: page_struct.entries,
						page: page_num,
						total_pages: page_struct.total_pages
						}}
				"invited_rooms" ->
					page_struct = get_paginated_rooms(socket.assigns[:player], page_num, :invited_rooms)
					%{invited_rooms: %{
							rooms: page_struct.entries,
							page: page_num,
							total_pages: page_struct.total_pages
						}}
				"players" ->
					page_struct = get_paginated_players(socket, page_num)
					%{players: page_struct.entries,
						page: page_num,
						total_pages: page_struct.total_pages}
				_ -> %{error: "Invalid list type #{type} was given to pagination"}
			end

		case params do
			%{error: _msg} -> push socket, "error", params
			_ -> push socket, "new_#{type}", params
		end
		{:noreply, socket}
	end

	defp send_room_update(socket, page_num, player, which_rooms \\ :both) do
		paginated_current_rooms = get_paginated_rooms(player, page_num, :participating_rooms)
		paginated_invited_rooms = get_paginated_rooms(player, page_num, :invited_rooms)

		Logger.debug "[PrivateRoomChannel] Pushing current and invited rooms to channel client"
		case which_rooms do
			:both -> push socket, "current_rooms",
				%{current_rooms: build_paginated_rooms(paginated_current_rooms, page_num),
					invited_rooms: build_paginated_rooms(paginated_invited_rooms, page_num)
				 }
			:current -> push socket, "current_rooms",
				%{current_rooms: build_paginated_rooms(paginated_current_rooms, page_num), invited_rooms: %{}}
			:invited -> push socket, "current_rooms",
				%{current_rooms: %{}, invited_rooms: build_paginated_rooms(paginated_invited_rooms, page_num)}
		end
	end

	defp send_player_list(socket, page_num) do
		paginated_list = get_paginated_players(socket, page_num)
		push socket, "player_list",
			%{players: paginated_list.entries,
				page: page_num,
				total_pages: paginated_list.total_pages}
	end

	defp get_paginated_rooms(%Player{} = player, page_num, type) do
		for room <- Enum.map(Map.get(player, type), &(&1.title)) do
			%{room: room,
				player_count: PrivateRoom.check_state(room).seating |> length(),
				is_owner: PrivateRoom.is_owner?(player, room) }
		end
			|> Scrivener.paginate(%Scrivener.Config{page_number: page_num, page_size: 10})
	end

	defp get_paginated_players(socket, page_num) do
		socket.assigns[:player_list]
			|> Scrivener.paginate(%Scrivener.Config{page_number: page_num, page_size: 25})
	end

	defp build_paginated_rooms(pagination_data, page_num) do
		%{rooms: pagination_data.entries, page: page_num, total_pages: pagination_data.total_pages}
	end

	defp format(errors) when is_list(errors) do
		errors
			|> Enum.map(fn {key, {error_msg, _}} -> "#{Atom.to_string(key) |> String.capitalize()} #{error_msg}" end)
	end

	defp format(_), do: ["An error occurred"]
end