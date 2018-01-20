defmodule PokerEx.PlayerTest do
	use ExUnit.Case
	use PokerEx.ModelCase
	import PokerEx.TestHelpers
	alias PokerEx.Player

	setup do
		player = insert_user()
		|> Map.put(:password, nil) # The :password field is virtual and gets overwritten when recorded in the DB

		{:ok,  player: player}
	end

	describe "Player" do
		test "all/0 returns a list of players", context do
			all_players = Player.all()
			assert is_list(all_players)
			assert context.player in all_players
		end

		test "delete/1 removes a player from the database", context do
			assert Player.delete(context.player) == :ok
		end

		test "paginate/1 returns a paginated struct with entries of players", _context do
			PokerEx.Repo.insert(%Player{name: "user#{Base.encode16(:crypto.strong_rand_bytes(8))}"})
			paginated = Player.paginate([page_num: 1])
			# Test player names all begin with "user", except for those inserted in the test below
			# Checking that the `name` string contains "user" works for now, but may break if
			# the database is ever blown away.
			Enum.each(paginated.entries, fn name -> assert String.contains?(name, "user") end)
			assert length(paginated.entries) <= 10
		end

		test "search/1 returns a list with names similar to the search query", _context do
			player = insert_user(%{name: "Sear#{Base.encode16(:crypto.strong_rand_bytes(8))}"})
			results = Player.search("sear")
			assert is_list(results)
			assert player.name in results
		end

		test "by_name/1 returns a player struct given a unique player name", context do
			assert Player.by_name(context.player.name) == context.player
		end

		test "by_name/1 returns an error tuple when given a non-existent username", _context do
			assert Player.by_name("non-existent user") == {:error, :player_not_found}
		end

		test "chips/1 returns the total available chip count for an existing user", context do
			assert Player.chips(context.player.name) == context.player.chips
		end

		test "chips/1 returns an error tuple when given a non-existent username", _context do
			assert Player.chips("non-existent user") == {:error, :player_not_found}
		end

		test "reward/3 takes a player and returns a player with the specified amount of chips added", context do
			{:ok, updated_player} = Player.reward(context.player.name, 200, :room_number)
			assert updated_player.chips == context.player.chips + 200
		end

		test "reward/3 returns an error tuple when given a non-existent username", _context do
			assert Player.reward("non-existent user", 300, :room_number) == {:error, :player_not_found}
		end

		test "update_chips/2 is an alias for reward/3 when given positive chip amounts", context do
			{:ok, updated_player} = Player.update_chips(context.player.name, 200)
			assert updated_player.chips == context.player.chips + 200
		end

		test "update_chips/2 returns an error tuple when given negative chip amounts", context do
			assert Player.update_chips(context.player.name, -200) == {:error, :negative_chip_amount}
		end

		test "update_chips/2 returns an error tuple when given a non-existent user", _context do
			assert Player.update_chips("non-existent user", 200) == {:error, :player_not_found}
		end

		test "subtract_chips/2 takes a player and returns a player with the specified amount of chips subtracted", context do
			{:ok, updated_player} = Player.subtract_chips(context.player.name, 200)
			assert updated_player.chips == context.player.chips - 200
		end

		test "subtract_chips/2 does not modify the player if the subtraction amount is > player.chips", context do
			{:ok, non_updated_player} = Player.subtract_chips(context.player.name, 1_000_000)
			assert non_updated_player == context.player
		end

		test "subtract_chips/2 returns an error tuple when given a non-existent user", _context do
			assert Player.subtract_chips("non-existent user", 200) == {:error, :player_not_found}
		end

		test "player_names/0 returns a list of all players' names", _context do
			[p1, p2|_] = Player.player_names()
			player1 = Player.by_name(p1)
			player2 = Player.by_name(p2)
			assert player1.name == p1
			assert player2.name == p2
		end

		test "fb_login_or_create/1 returns an existing player with a FB id and matching name", _ do
			{id, name} = { Base.encode16(:crypto.strong_rand_bytes(8)), "person guy"}
			{:ok, player} = Repo.insert(%Player{facebook_id: id, name: name})
			result = Player.fb_login_or_create(%{facebook_id: id, name: name})
			assert player == result
		end

		test "fb_login_or_create/1 creates a new player if no player with that FB id exists", _ do
			{id, name} =
				{Base.encode16(:crypto.strong_rand_bytes(8)), "Name#{Base.encode16(:crypto.strong_rand_bytes(8))}"}
			result = Player.fb_login_or_create(%{facebook_id: id, name: name})
			# The assign name will add a `1` to the end of name that ends with a digit
			assert result.name == "#{name} #{1}" || result.name == name
			assert result.facebook_id == id
			assert result.chips == 1000
		end

		test "create_oauth_user/1 returns an invalid changeset if given a name of an existing user", _ do
			duplicate_name = "john appleseed"
			{:ok, _} = Repo.insert(%Player{name: duplicate_name}) # Setup player in DB
			# Create fake oauth_user
			fake_fb_id = Base.encode16(:crypto.strong_rand_bytes(8))
			player = Player.create_oauth_user(%{name: duplicate_name, provider_data: [facebook_id: fake_fb_id]})
			refute player.name == duplicate_name
			assert Regex.match?(~r/\d/, String.last(player.name))
		end
	end
end