defmodule PokerExWeb.PrivateRoomChannelTest do
	use PokerExWeb.ChannelCase
	import PokerEx.TestHelpers
	alias PokerExWeb.PrivateRoomChannel
	alias PokerEx.PrivateRoom
	alias PokerEx.Player

	@endpoint PokerExWeb.Endpoint
	@players_per_page 25

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

	test "a `player_list` message is pushed on successful joins", context do
		first_page_names =
			Player.all()
			|> Stream.map(&(&1.name))
			|> Stream.reject(&(&1 == context.player.name))
			|> Enum.take(@players_per_page)

		first_page_names = Enum.reject(first_page_names, &(&1 == context.player.name))

		assert_push "player_list", %{players: ^first_page_names, page: 1, total_pages: _}
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

	test "`create_room` message creates a new room with the given title", context do
		# TODO: Take one of the invited players and `subscribe_and_join` the `notifications_channel:#{name}`
		# for that player. When a `create_room` message is received in the PrivateRoomChannel, it
		# should also trigger a `broadcast` to the NotificationsChannel for each invited player.
		title = "test#{Base.encode16(:crypto.strong_rand_bytes(8))}"
		ref = push context.socket, "create_room",
			%{"title" => title,
				"owner" => context.player.name, "invitees" => Enum.map(context.room.invitees, &(&1.name))}

		assert_reply ref, :ok # Make sure that the reply has been sent
	end

	test "`create_room` fails and returns an error response if given a duplicate room name", context do
		room = PrivateRoom.preload(context.room)
		invitees = Enum.map(context.room.invitees, &(&1.name))
		ref = push context.socket, "create_room",
			%{"title" => room.title, "owner" => context.player.name, "invitees" => invitees}

		assert_reply ref, :error
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