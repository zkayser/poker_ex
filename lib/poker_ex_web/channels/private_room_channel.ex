defmodule PokerExWeb.PrivateRoomChannel do
	use Phoenix.Channel
	require Logger
	alias PokerEx.Player

	def join("private_rooms:" <> player_name, _params, socket) do
		with %Player{} = player <- Player.by_name(player_name) do
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
		update_and_assign_rooms(socket, 1)
		{:noreply, socket}
	end

	defp update_and_assign_rooms(socket, page_num) do
		player = Player.preload(socket.assigns[:player])
		paginated_current_rooms = get_paginated_current_rooms(player, page_num)
		paginated_invited_rooms = get_paginated_invited_rooms(player, page_num)

		Logger.debug "[PrivateRoomChannel] Pushing current and invited rooms to channel client"
		push socket, "current_rooms",
			%{current_rooms: %{
					rooms: paginated_current_rooms.entries,
					page: page_num,
					total_pages: paginated_current_rooms.total_pages
				 },
				invited_rooms: %{
					rooms: paginated_invited_rooms.entries,
					page: page_num,
					total_pages: paginated_invited_rooms.total_pages
				}
			 }
	end

	defp get_paginated_current_rooms(%Player{} = player, page_num) do
		Enum.map(player.participating_rooms, &(String.to_atom(&1.title)))
			|> Scrivener.paginate(%Scrivener.Config{page_number: page_num, page_size: 10})
	end

	defp get_paginated_invited_rooms(%Player{} = player, page_num) do
		Enum.map(player.invited_rooms, &(String.to_atom(&1.title)))
			|> Scrivener.paginate(%Scrivener.Config{page_number: page_num, page_size: 10})
	end
end