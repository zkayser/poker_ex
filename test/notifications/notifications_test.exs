defmodule PokerEx.NotificationsTest do
	use PokerExWeb.ChannelCase
	import PokerEx.TestHelpers
	alias PokerExWeb.NotificationsChannel, as: Channel
	alias PokerEx.Notifications
	alias PokerEx.PrivateRoom

	@endpoint PokerExWeb.Endpoint

	setup do
		{socket, player, token, reply} = create_player_and_connect()

		{:ok, socket: socket, player: player, token: token, reply: reply}
	end

	test "notify_invitees/2 broadcasts an `invitation_received` message on the channel", context do
		player = insert_user()
		{:ok, room} = PrivateRoom.create("Test#{random_string()}", player, [context.player])
		Notifications.notify_invitees(room)

		expected_payload = %{title: room.title, owner: player.name}

		assert_broadcast "invitation_received", ^expected_payload
	end

	test "notify_invitees/2 broadcasts a `room_deleted` message on the notifications channel", context do
		player = insert_user()
		{:ok, room} = PrivateRoom.create("Test#{random_string()}", player, [context.player])
		Notifications.notify_invitees(room, :deletion)

		expected_payload = %{title: room.title, owner: player.name}

		assert_broadcast "room_deleted", ^expected_payload
	end

	test "notify_invitees/2 with explicit options", context do
		player = insert_user()
		{:ok, room} = PrivateRoom.create("Test#{random_string()}", player, [context.player])
		Notifications.notify([owner: room.owner, title: room.title, recipients: [context.player]], :deletion)

		expected_payload = %{title: room.title, owner: player.name}

		assert_broadcast "room_deleted", ^expected_payload
	end

	defp create_player_and_connect do
		player = insert_user()

		token = Phoenix.Token.sign(socket(), "user socket", player.id)

		{:ok, socket} = connect(PokerExWeb.UserSocket, %{"token" => token})

		{:ok, reply, socket} = subscribe_and_join(socket, Channel, "notifications:#{player.name}")

		{socket, player, token, reply}
	end
end