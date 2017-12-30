defmodule PokerExWeb.PrivateRoomChannelTest do
	use PokerExWeb.ChannelCase
	import PokerEx.TestHelpers
	alias PokerExWeb.PrivateRoomChannel

	@endpoint PokerExWeb.Endpoint

	setup do
		{socket, player, token, reply} = create_player_and_connect()

		{:ok, socket: socket, player: player, token: token, reply: reply}
	end

	test "it join replies with `:success` when authentication is successful", context do
		assert context.reply.response == :success
	end

	defp create_player_and_connect do
		player = insert_user()
		name = player.name
		token = Phoenix.Token.sign(socket(), "user socket", player.id)

		{:ok, socket} = connect(PokerExWeb.UserSocket, %{"token" => token})

		with {:ok, reply, socket} <- subscribe_and_join(socket, PrivateRoomChannel, "private_rooms:" <> name) do
			{socket, player, token, reply}
		else {:error, reply} -> {socket, player, token, reply}
		end
	end
end