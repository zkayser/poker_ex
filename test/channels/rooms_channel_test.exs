defmodule PokerEx.RoomChannelTest do
	use PokerExWeb.ChannelCase
	import PokerEx.TestHelpers
	alias PokerExWeb.RoomsChannel
	alias PokerEx.Room
	alias PokerEx.RoomsSupervisor, as: RoomSup

	@endpoint PokerExWeb.Endpoint
	@default_chips 500

	setup do
		title = "room_#{Base.encode16(:crypto.strong_rand_bytes(8))}"
		{:ok, _} = RoomSup.find_or_create_process(title)

		{socket, player, token, reply} = create_player_and_connect(title)
		@endpoint.subscribe("rooms:#{title}")

		{:ok, socket: socket, player: player, token: token, reply: reply, title: title}
	end

	test "authentication works", context do
		assert {:player_id, context.player.id} in context.socket.assigns
	end

	test "room join", context do
		for key <- [:join_amount, :player, :type, :room] do
			assert key in Map.keys(context.socket.assigns)
		end

		seated_players = for {player, _pos} <- Room.state(context.title).seating, do: player

		assert context.player.name in seated_players
		assert Room.which_state(context.title) == :idle
	end

	test "room join for private room", context do
		# Setup a new room and channel process
		# Connect with the player
		# Leave the channel
		# Rejoin the channel with :join_amount = 0
		# Test that %{message: :ok} is returned.
	end

	test "a game starts when a second player joins", context do
		{_, player, _, _} = create_player_and_connect(context.title)

		room_state = Room.state(context.title)
		seated_players = for {player, _} <- room_state.seating, do: player

		for player <- [context.player.name, player.name], do: assert player in seated_players

		assert_broadcast "update",
			%{active: _, chip_roll: %{}, paid: %{},
				player_hands: [%{hand: [%{rank: _, suit: _}, %{rank: _, suit: _}], player: _},
											 %{hand: [%{rank: _, suit: _}, %{rank: _, suit: _}], player: _}
											],
				players: [%{chips: _, name: _}, %{chips: _, name: _}],
				pot: 15,
				round: %{},
				seating: [%{name: _, position: _}, %{name: _, position: _}],
				table: [],
				to_call: 10,
				type: "public"
			 }
		assert Room.which_state(context.title) == :pre_flop
	end

	test "channel broadcasts actions taken by players", context do
		{_, player, _, _} = create_player_and_connect(context.title)
		player_name = player.name

		{active_player, _} = Room.state(context.title).active |> hd()
		assert active_player == context.player.name

		push context.socket, "action_raise", %{"player" => context.player.name, "amount" => 25}

		assert_broadcast "update", %{active: ^player_name, pot: 45}

		push context.socket, "action_call", %{"player" => player.name}

		assert_broadcast "update", %{active: ^active_player, pot: 70}

		push context.socket, "action_check", %{"player" => context.player.name}

		assert_broadcast "update", %{active: ^player_name, pot: 70}

		push context.socket, "action_check", %{"player" => player.name}

		push context.socket, "action_raise", %{"player" => context.player.name, "amount" => 50}

		assert_broadcast "update", %{active: ^player_name, pot: 120}

		push context.socket, "action_fold", %{"player" => player.name}

		assert_broadcast "update", %{state: :turn}

		assert_broadcast "winner_message", %{message: _}

		assert_broadcast "game_finished", %{message: _}
	end

	test "a new update message is broadcast when a player manually sends a leave message", context do
		{_, player, _, _} = create_player_and_connect(context.title)

		seating = Room.state(context.title).seating
		assert length(seating) == 2
		assert Room.which_state(context.title) == :pre_flop

		expected_player_remaining = context.player.name

		push context.socket, "action_leave", %{"player" => player.name}

		assert_broadcast "update", %{seating: [%{name: ^expected_player_remaining, position: 0}]}

		Process.sleep(100)
		seating_after_leave = Room.state(context.title).seating
		assert length(seating_after_leave) == 1
	end

	test "a new update message is broadcast when a player's channel is disconnected", context do
		{_, player, _, _} = create_player_and_connect(context.title)

		# Since a :skip_update_message is returned if there are only two players
		# and one leaves/gets disconnected (leaving only one player at the table), I'm having a
		# third player join here to invoke what would normally be returned given an ongoing game with
		# more than two players.

		{_, other_player, _, _} = create_player_and_connect(context.title)

		assert length(Room.state(context.title).seating) == 3
		assert Room.which_state(context.title) == :pre_flop

		expected_seating = [%{name: player.name, position: 0}, %{name: other_player.name, position: 1}]

		leave(context.socket)

		assert_broadcast "update", %{seating: ^expected_seating}

		Process.sleep(100)
		assert length(Room.state(context.title).seating) == 2
	end

	test "when there are only two players and one leaves, the channel broadcasts a 'clear_ui' message", context do
		{socket, _, _, _} = create_player_and_connect(context.title)

		assert length(Room.state(context.title).seating) == 2

		leave(socket)

		Process.sleep(100)
		assert_broadcast "clear_ui", %{}
	end

	test "the channel issues a push with the number of available chips when receiving a 'get_bank' message", context do
		push context.socket, "get_bank", %{"player" => context.player.name}

		chips = PokerEx.Player.chips(context.player.name)

		assert_push "bank_info", %{chips: ^chips}
	end

	test "the channel broadcasts an update when a player submits an add_chips action", context do
		create_player_and_connect(context.title)

		player_name = context.player.name
		push context.socket, "action_add_chips", %{"player" => player_name, "amount" => 200}

		Process.sleep(100)
		chips = Room.state(context.title).chip_roll[player_name]

		assert_broadcast "update", %{chip_roll: %{^player_name => ^chips}}
	end

	test "the channel broadcasts `new_chat_msg` in response to `chat_msg` incoming messages", context do
		create_player_and_connect(context.title)

		player_name = context.player.name
		message = "What's up y'all?"
		push context.socket, "chat_msg", %{"player" => context.player.name, "message" => message}

		assert_broadcast "new_chat_msg", %{player: ^player_name, message: ^message}
	end

	defp create_player_and_connect(title) do
		player = insert_user()

		token = Phoenix.Token.sign(socket(), "user socket", player.id)

		{:ok, socket} = connect(PokerExWeb.UserSocket, %{"token" => token})

		{:ok, reply, socket} = subscribe_and_join(socket, RoomsChannel, "rooms:#{title}",
																							%{"type" => "public", "amount" => @default_chips})

		{socket, player, token, reply}
	end
end