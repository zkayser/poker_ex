defmodule LobbyChannelTest do
	use PokerExWeb.ChannelCase
	import PokerEx.TestHelpers
	alias PokerExWeb.LobbyChannel

	@endpoint PokerExWeb.Endpoint

	setup do
		{socket, player, reply} = create_player_and_connect()

		{:ok, socket: socket, player: player, reply: reply}
	end

	test "join replies with success", context do
		assert context.reply.response == :success
	end

	test "after joining, the channel pushes a list of public rooms", _context do
		assert_push "rooms", %{rooms: _, page: 1, total_pages: 10}
	end

	test "a `player_count_updated` message is broadcast whenever a player joins or leaves a public room", context do
		token = Phoenix.Token.sign(context.socket, "user socket", context.player.id)

		{:ok, socket} = connect(PokerExWeb.UserSocket, %{"token" => token})

		{:ok, _, _} = subscribe_and_join(socket, PokerExWeb.RoomsChannel, "rooms:room_1",
																			%{"type" => "public", "amount" => 500})

		assert_broadcast "update_player_count", _
	end

	test "the channel pushes the correctly paginated list of rooms when receiving a `get_page` message", context do
		push context.socket, "get_page", %{"page_num" => "3"}
		assert_push "rooms", %{rooms: _, page: 3, total_pages: 10}
	end

	defp create_player_and_connect() do
    player = insert_user()

    {:ok, socket} = connect(PokerExWeb.UserSocket, %{"name" => player.name})

    {:ok, reply, socket} = subscribe_and_join(socket, LobbyChannel, "lobby:lobby")

    {socket, player, reply}
  end
end