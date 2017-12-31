defmodule PokerExWeb.PrivateRoomChannelTest do
	use PokerExWeb.ChannelCase
	import PokerEx.TestHelpers
	alias PokerExWeb.PrivateRoomChannel
	alias PokerEx.PrivateRoom
	alias PokerEx.Player

	@endpoint PokerExWeb.Endpoint

	setup do
		{socket, player, token, reply, room} = create_player_and_connect()

		{:ok, socket: socket, player: player, token: token, reply: reply, room: room}
	end

	test "join replies with `:success` when authentication is successful", context do
		assert context.reply.response == :success
	end

	test "a `current_rooms` message is pushed on successful joins", context do
		room_process = String.to_atom(context.room.title)

		expected_current_rooms = %{rooms: [%{room: room_process, player_count: 0}], page: 1, total_pages: 1}

		expected_invited_rooms = %{rooms: [], page: 1, total_pages: 0}

		assert_push "current_rooms",
			%{current_rooms: ^expected_current_rooms,
				invited_rooms: ^expected_invited_rooms
			 }
	end

	test "`accept_invititation` messages trigger updates to the accepting player's participating_rooms", context do
		invited_player = PrivateRoom.preload(context.room) |> Map.get(:invitees) |> hd()

		push context.socket, "accept_invitation", %{"player" => invited_player.name, "room" => context.room.title}

		Process.sleep(50)
		updated_player = Player.by_name(invited_player.name) |> Player.preload()
		updated_room = PrivateRoom.by_title(context.room.title) |> PrivateRoom.preload()

		assert updated_room.id in Enum.map(updated_player.participating_rooms, &(&1.id))
		refute updated_room.id in Enum.map(updated_player.invited_rooms, &(&1.id))
	end

	defp create_player_and_connect do
		player = insert_user()
		invited_players = for _ <- 1..4, do: insert_user()
		{:ok, room} = PrivateRoom.create("test#{Base.encode16(:crypto.strong_rand_bytes(8))}", player, invited_players)
		name = player.name
		token = Phoenix.Token.sign(socket(), "user socket", player.id)

		{:ok, socket} = connect(PokerExWeb.UserSocket, %{"token" => token})

		with {:ok, reply, socket} <- subscribe_and_join(socket, PrivateRoomChannel, "private_rooms:" <> name) do
			{socket, player, token, reply, room}
		else {:error, reply} -> {socket, player, token, reply, room}
		end
	end
end