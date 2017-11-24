defmodule PokerEx.PlayerTest do
	use ExUnit.Case
	use PokerEx.ModelCase
	import PokerEx.TestHelpers
	alias PokerEx.Player

	setup do
		player = insert_user()

		{:ok,  player: player}
	end

	describe "Player" do
		test "Player.chips/1 returns the chips available for a player given a player's name", %{player: player} do
			assert Player.chips(player.name) == %{chips: player.chips}
		end

		test "Player.chips/1 returns an error tuple when given a non-existent player", _context do
			assert Player.chips("some username that doesn't exist") == {:error, :player_not_found}
		end
	end
end