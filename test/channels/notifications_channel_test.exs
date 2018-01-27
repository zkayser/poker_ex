defmodule PokerEx.NotificationsChannelTest do
	use PokerExWeb.ChannelCase
	import PokerEx.TestHelpers
	alias PokerExWeb.NotificationsChannel

	@endpoint PokerExWeb.Endpoint

	setup do
		{socket, player, token, reply} = create_player_and_connect()

		{:ok, socket: socket, player: player, token: token, reply: reply}
	end

	test "channel replies with :ok on join", context do
		assert context.reply.status == :ok
	end

	defp create_player_and_connect do
		player = insert_user()

		token = Phoenix.Token.sign(socket(), "user socket", player.id)

		{:ok, socket} = connect(PokerExWeb.UserSocket, %{"token" => token})

		{:ok, reply, socket} = subscribe_and_join(socket, NotificationsChannel, "notifications:#{player.name}")

		{socket, player, token, reply}
	end
end