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
		push socket, "rooms", %{rooms: show_rooms()}
		{:noreply, socket}
	end

	defp show_rooms do
		for room <- RoomServer.get_rooms() do
			%{name: room, player_count: Room.state(room).seating |> length()}
		end
	end
end