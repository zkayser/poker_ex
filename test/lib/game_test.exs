defmodule PokerEx.GameTest do
	use ExUnit.Case
	alias PokerEx.Player
	alias PokerEx.Game
	alias PokerEx.Evaluator
	
	@player1 %Player{name: "player 1", chips: 1000}
	@player2 %Player{name: "player 2", chips: 1000}
	@player3 %Player{name: "player 3", chips: 1000}
	@players [@player1, @player2, @player3]
	@new Game.new |> Map.put(:players, @players)
	@game Game.start(@new)
	
	test "starting a game deals two cards to each player" do
		assert Enum.all?(@game.players, fn {player, hand} -> length(hand) == 2 end)
	end
	
	test "deal_flop places three cards on the table" do
		game = Game.deal_flop(@game)
		assert length(game.table) == 3
	end
	
	test "calling deal_one after deal_flop puts 4 cards on the table (flop + turn)" do
		game = Game.deal_flop(@game) |> Game.deal_one
		assert length(game.table) == 4
	end
	
	test "calling deal_one twice after deal_flop puts the turn and river on the table (flop + turn + river)" do
		game = Game.deal_flop(@game) |> Game.deal_one |> Game.deal_one
		assert length(game.table) == 5
	end
	
	test "calling deal_one more than twice after calling deal_flop raises an error" do
		assert_raise ArgumentError, fn ->
			Game.deal_flop(@game) |> Game.deal_one |> Game.deal_one |> Game.deal_one
		end
	end
	
	test "calling determine_winner raises errors unless five cards have been dealt on the table" do
		game = Game.deal_flop(@game)
		assert_raise ArgumentError, fn ->
			Game.determine_winner(game)
		end
		game = Game.deal_one(game)
		assert_raise ArgumentError, fn ->
			Game.determine_winner(game)
		end
	end
	
	test "calling determine_winner chooses the player with best hand" do
		game = Game.deal_flop(@game) |> Game.deal_one |> Game.deal_one |> Game.determine_winner
		[{winner, winning_hand}|_] = game.winner
		scores = 
			for {player, hand} <- game.players do
				Evaluator.evaluate_hand(hand, game.table)
			end
			|> Enum.map(fn hand -> hand.score end)
		assert Enum.max(scores) == winning_hand.score
	end
end