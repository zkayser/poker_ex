defmodule PokerEx.RoomChannelTest do
	use PokerExWeb.ChannelCase
	import PokerEx.TestHelpers
	alias PokerExWeb.RoomsChannel
	alias PokerEx.Player
	alias PokerEx.Room

	@endpoint PokerExWeb.Endpoint

	setup do
		player = insert_user()

		{:ok, room_pid} = Room.start_link("room_test")

		token = Phoenix.Token.sign(socket(), "user socket", player.id)

		{:ok, socket} = connect(PokerExWeb.UserSocket, %{"token" => token})

		{:ok, reply, socket} = subscribe_and_join(socket, RoomsChannel, "rooms:room_test", 
																					%{"type" => "public", "amount" => 500})

		{:ok, socket: socket, player: player, token: token, reply: reply}
	end

	test "authentication works", context do
		assert {:player_id, context.player.id} in context.socket.assigns
	end

	test "room join", context do
		for key <- [:join_amount, :player, :type, :room] do
			assert key in Map.keys(context.socket.assigns)
		end

		seated_players = 
			for {player, _pos} <- Room.state(:room_test).seating do
				player
			end

		assert context.player.name in seated_players
	end
end