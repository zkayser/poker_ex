defmodule GameFSMTest do
	use ExUnit.Case
	alias PokerEx.GameFSM
	alias PokerEx.Player
	alias PokerEx.AppState
	alias PokerEx.Game
	
	@player1 %Player{name: "player1", chips: 1000}
	@player2 %Player{name: "player2", chips: 1000}
	@player3 %Player{name: "player3", chips: 1000}
	@players [@player1, @player2, @player3]
	
	setup do 
		Enum.each(@players, &(AppState.put(&1)))
		GameFSM.clear
	end
	
	test "no hand is dealt until at least two players join the table" do
		GameFSM.join(@player1)
		game = Game.new
		game = %Game{ game | sitting: [@player1.name], players: [@player1.name], current_paid: [{0, @player1.name}] }
		assert GameFSM.get_state == game
	end
	
	test "hands are dealt when a second player joins the table" do
		Enum.each(@players, &(GameFSM.join(&1)))
		game = GameFSM.get_state
		players = game.players
		
		[{_, hand1}, {_, hand2}] = players
		assert length(hand1) == 2
		assert length(hand2) == 2
		
		names = Enum.map(@players, &(&1.name))
		Enum.each(names, &(assert &1 in game.sitting))
	end
	
	test "big blind and small blind are posted when a game begins" do
	
	end
	
	test "a single call to raise_pot increases the pot size by given amount when player has sufficient chips" do
		set_game
		game = GameFSM.raise_pot(@player1, 20)
		
		p1_paid = Enum.filter(game.current_paid, fn {paid, player} -> paid == 20 && player == @player1.name end) |> hd()
		{amount_paid, _} = p1_paid
		
		assert game.pot == 20
		assert p1_paid in game.current_paid
		assert amount_paid = 20
	end
	
	test "puts a player all in if the player tries to raise by an amount greater than the number of chips they have" do
		clear
		set_game
		game = GameFSM.raise_pot(@player1, 10_000)
		
		paid = Enum.filter(game.current_paid, fn {pd, name} -> name == @player1.name end) |> hd()
		
		assert @player1.name in game.all_in
		assert paid == {1000, @player1.name}
	end
	
	test "puts a player all in if they call when the call_amount is greater than the number of chips they have" do
		clear
		set_game
		Player.bet("player2", 950)
		
		game = GameFSM.raise_pot(@player1, 100)
		game = GameFSM.call_pot(@player2)
	
		assert @player2.name in game.all_in
	end

	defp clear do
		Enum.each(@players, &(AppState.delete(&1)))
		Enum.each(@players, &(AppState.put(&1)))
	end
	
	def set_game do
		Enum.each(@players, &(GameFSM.join(&1)))
	end
	
	def simulate_one do
		set_game
		GameFSM.raise_pot(@player1, 10)
		GameFSM.call_pot(@player2)
		GameFSM.raise_pot(@player1, 10)
		GameFSM.call_pot(@player2)
		GameFSM.raise_pot(@player1, 10)
		GameFSM.call_pot(@player2)
		GameFSM.raise_pot(@player1, 10)
		GameFSM.call_pot(@player2)
	end
end