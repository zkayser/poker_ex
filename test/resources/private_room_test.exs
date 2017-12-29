defmodule PokerEx.PrivateRoomTest do
	use ExUnit.Case
	use PokerEx.ModelCase
	import PokerEx.TestHelpers
	alias PokerEx.PrivateRoom, as: PRoom
	alias PokerEx.Player

	setup do
		player = insert_user()

		{:ok, player: player}
	end

	test "create/3 instantiates a new `PrivateRoom` instance", %{player: player} do
		title = "room_title#{Base.encode16(:crypto.strong_rand_bytes(8))}"
		invitees = for _ <- 1..4, do: insert_user()
		{:ok, room} = PRoom.create(title, player, invitees)

		assert room.owner == player
		assert room.invitees == invitees
		assert room.title == title
	end


end