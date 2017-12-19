defmodule PokerEx.RoomServerTest do
	use ExUnit.Case
	alias PokerEx.RoomServer

	@initial_room_count Application.get_env(PokerEx, :initial_room_count)

	test "it exists" do
		assert Process.whereis(RoomServer) |> Process.alive?
	end

	test "get_rooms returns a list of rooms running on the server" do
		assert length(RoomServer.get_rooms()) == @initial_room_count
	end
end