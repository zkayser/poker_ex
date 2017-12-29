defmodule PokerEx.PrivateRoomTest do
	use ExUnit.Case
	use PokerEx.ModelCase
	import PokerEx.TestHelpers
	alias PokerEx.PrivateRoom, as: PRoom
	alias PokerEx.Player

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
end