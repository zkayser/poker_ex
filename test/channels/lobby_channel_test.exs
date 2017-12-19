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

	defp create_player_and_connect() do
    player = insert_user()

    {:ok, socket} = connect(PokerExWeb.UserSocket, %{"name" => player.name})

    {:ok, reply, socket} = subscribe_and_join(socket, LobbyChannel, "lobby:lobby")

    {socket, player, reply}
  end
end