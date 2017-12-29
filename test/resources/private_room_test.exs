defmodule PokerEx.PrivateRoomTest do
	use ExUnit.Case
	use PokerEx.ModelCase
	import PokerEx.TestHelpers
	alias PokerEx.PrivateRoom, as: PRoom
	alias PokerEx.Player
	alias PokerEx.Room

	setup do
		player = insert_user()

		invitees = for _ <- 1..4, do: insert_user()

		{:ok, room} = PRoom.create("room#{Base.encode16(:crypto.strong_rand_bytes(8))}", player, invitees)

		{:ok, player: player, invitees: invitees, room: room}
	end

	test "create/3 instantiates a new `PrivateRoom` instance", %{player: player} do
		title = "room_title#{Base.encode16(:crypto.strong_rand_bytes(8))}"
		invitees = for _ <- 1..4, do: insert_user()
		{:ok, room} = PRoom.create(title, player, invitees)

		assert room.owner == player
		assert room.invitees == invitees
		assert room.title == title
		assert room.id in Enum.map(Player.preload(player).owned_rooms, &(&1.id)) # Player owns the room
		assert player in room.participants # The owner is included in participants by default
		assert Process.alive?(Process.whereis(String.to_atom(title))) # Creates the room process
	end

	test "accept_invitation/2 moves a player from the invitees list to `participants`", context do
		participant = hd(context.invitees)

		{:ok, room} = PRoom.accept_invitation(context.room, participant)

		assert participant in room.participants
		refute participant in room.invitees

		updated_participant = Player.get(participant.id)

		assert room.id in Enum.map(Player.preload(updated_participant).participating_rooms, &(&1.id))
		refute room.id in Enum.map(Player.preload(updated_participant).invited_rooms, &(&1.id))
	end

	test "decline_invitation/2 removes a player from the invitees list", context do
		declining_player = hd(context.invitees)

		{:ok, room} = PRoom.decline_invitation(context.room, declining_player)

		refute declining_player in room.invitees
	end

	test "leave_room/2 removes a player from the `participants` and `Room` instance if seated", context do
		leaving_player = hd(context.invitees)

		{:ok, room} = PRoom.accept_invitation(context.room, leaving_player) # First join the participants

		room_process = String.to_atom(context.room.title)

		Room.join(room_process, leaving_player, 200)

		# Ensure that the player successfully joined the room.
		assert leaving_player.name in Enum.map(Room.state(room_process).seating, fn {pl, _} -> pl end)

		{:ok, room} = PRoom.leave_room(room, leaving_player)
		refute leaving_player in room.participants

		# Should also remove the player from the `Room` instance
		refute leaving_player.name in Enum.map(Room.state(room_process).seating, fn {pl, _} -> pl end)
	end
end