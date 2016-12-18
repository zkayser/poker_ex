defmodule PokerEx.Game do
	@moduledoc """
	Defines a struct for containing game state and information
	including the players involved in the game, cards dealt on
	the table, the current deck, and winner.
	
	Also provides utility functions for use in updating and working
	with games in the GameState module where an Agent is used to
	store state asynchronously.
	"""
	alias PokerEx.Game
	alias PokerEx.Player
	alias PokerEx.Card
	alias PokerEx.Deck
	alias PokerEx.Evaluator
	alias PokerEx.AppState
	alias PokerEx.TableState, as: State
	
	@type t :: %Game{players: [String.t] | [{String.T, [Card.t]}], table: [Card.t], ready: [Player.t] | [],
									 deck: Deck.t, winner: Player.t | nil, pot: non_neg_integer, all_in: [] | [Player.t],
									 to_call: integer, called: [Player.t] | [], sitting: [Player.t] | [], state: State.t
									 }
									 
	defstruct players: [], table: [], deck: nil, ready: [],
						winner: nil, pot: 0, sitting: [], all_in: [],
						to_call: 0, called: [], current_paid: [], state: %State{}
	
	@doc """
	Initiates a new game
	"""
	@spec new() :: Game.t
	def new do
		%Game{}
	end
	
	@spec start([Player.t]) :: Game.t		
	def start(game) do
		%Game{game | deck: Deck.new |> Deck.shuffle}
		|> deal_first_hand
	end
	def start(players), do: Enum.take(players, 9) |> Game.start
	
	@doc """
	Deals two cards to each player at the beginning of the game
	"""
	@spec deal_first_hand(Game.t) :: Game.t
	def deal_first_hand(%Game{players: players, deck: deck} = game) do
		{new_deck, updated_players} = _deal(players, deck, [], length(players))
		%Game{game | players: updated_players, deck: new_deck}
	end
	
	@doc """
	Deals three cards for the flop
	"""
	@spec deal_flop(Game.t) :: Game.t
	def deal_flop(%Game{table: table, deck: deck} = game) do
		{flop, remaining} = Deck.deal(deck, 3)
		%Game{game | table: table ++ flop, deck: remaining}
	end
	
	@doc """
	Deals one card for the turn/river
	"""
	@spec deal_one(Game.t) :: Game.t
	def deal_one(%Game{table: table, deck: deck} = game) when length(table) <= 4 do
		{card, remaining} = Deck.deal(deck, 1)
		%Game{game | table: table ++ card, deck: remaining}
	end
	def deal_one(_), do: raise ArgumentError, "No more than 5 cards can be dealt on the table"
	
	@spec determine_winner(Game.t) :: Game.t
	def determine_winner(%Game{players: players, table: table} = game) when length(players) == 1 do
		{pl, hand} = players
		%Game{ game | winner: [{pl, Evaluator.evaluate_hand(hand, table)}]}
	end
	def determine_winner(%Game{players: players, table: table} = game) when length(table) == 5 do
		contenders = for {pl, hand} <- players, into: %{} do
			{pl, Evaluator.evaluate_hand(hand, table)}
		end
			
		max = Enum.map(contenders, fn {pl, hand} -> hand.score end) |> Enum.max

		%Game{game| players: players, winner: Enum.filter(contenders, fn {contender, hand} -> hand.score == max end)}
	end
	def determine_winner(_), do: raise ArgumentError, "Cannot determine the winner unless five cards have been dealt"
	
	@spec fold(Game.t, Player.t) :: Game.t
	def fold(%Game{players: players, sitting: sitting} = game, player) do
		updated_players = Enum.reject(players, fn {n, _} -> n == player end)
		update = %Game{ game | players: updated_players}
		case length(update.players) do
			1 ->	%Game{update | winner: [player]}
			_ ->	update
		end
	end
	
	@spec raise_pot(Game.t, Player.t, pos_integer) :: Game.t
	def raise_pot(%Game{to_call: current, pot: pot, called: called, all_in: all_in, current_paid: cp} = game, player, amount) when amount > current do
		[{has_paid, _}] = Enum.filter(cp, fn {paid, n} -> n == player end)
		call_amount = amount - has_paid
		
		# If a player does not have enough chips, they will be placed in the all_in list and the pot will
		# only be incremented by the amount of chips they have available
		case Player.bet(player, call_amount) do
			%Player{name: _name, chips: _chips} -> 
				new_cp = Enum.map(cp, 
					fn {paid, n} -> 
						if n == player do
							{call_amount, n}
						else
							{paid, n}
						end
					end)
					%Game{ game | called: [player], to_call: amount, pot: pot + amount, current_paid: new_cp}
			:insufficient_chips -> 
				%Player{chips: chips} = AppState.get(player)
				new_cp = Enum.map(cp,
					fn {paid, n} ->
						if n == player do
							{chips, n}
						else
							{paid, n}
						end
				end)
				%Game{ game | all_in: [player|all_in], called: [player], to_call: chips, pot: pot + chips, current_paid: new_cp}
			_ ->
				raise ArgumentError, "Something went wrong in call to Player.bet"
		end
		
	end
	
	# The front end client should not offer the ability to call raise_pot when the player
	# has a chip count less than that of the current pot
	def raise_pot(_, _, _), do: raise ArgumentError, "Illegal operation"
	
	@spec call_pot(Game.t, Player.t) :: Game.t
	def call_pot(%Game{called: called, to_call: current, current_paid: cp, pot: pot, all_in: all_in} = game, player) do
		[{has_paid, _}] = Enum.filter(cp, fn {paid, n} -> n == player end)
		call_amount = current - has_paid
		
		case Player.bet(player, call_amount) do
			%Player{name: _name, chips: _chips} ->
				new_cp = Enum.map(cp,
					fn {paid, n} ->
						if n == player do
							{current, n}
						else
							{paid, n}
						end
					end)
				%Game{ game | called: [player|called], pot: pot + call_amount}
			:insufficient_chips ->
				%Player{chips: chips} = AppState.get(player)
				new_cp = Enum.map(cp,
					fn {paid, n} ->
						if n == player do
							{chips, n}
						else
							{paid, n}
						end
				end)
				%Game{ game | all_in: [player|all_in], called: [player], to_call: chips, pot: pot + chips, current_paid: new_cp}
			_ -> raise ArgumentError, "Something went wrong in call to Game.call_pot"
		end
		
	end
	
	@spec check(Game.t, Player.t) :: Game.t
	def check(%Game{called: called} = game, player) do
		%Game{game | called: [player|called]}
	end
	
	@doc """
	Resets the current_paid key to a list with only the players still playing.
	Leaves the paid amount as is for players who are all in.
	"""
	@spec reset_current_paid(Game.t) :: Game.t
	def reset_current_paid(%Game{all_in: all_in, current_paid: cp} = game) do
		current_paid = Enum.map(cp, fn {paid, player} -> unless player in all_in, do: {0, player}, else: {paid, player} end)
		%Game{ game | current_paid: current_paid}
	end
	
	@doc """
	Resets the to_call key to 0 between round
	"""
	@spec reset_to_call(Game.t) :: Game.t
	def reset_to_call(game) do
		%Game{game | to_call: 0}
	end
	
	@spec reward_winner(Game.t) :: [Player.t]
	def reward_winner(%Game{pot: pot, winner: winner}) when length(winner) == 1 do
		for {player, _} <- winner, do: AppState.get(player) |> Player.reward(pot)
	end
	def reward_winner(%Game{pot: pot, winner: winner}) do
		earnings = Float.ceil(pot / length(winner))
		for {player, _} <- winner do
			player
			|> AppState.get
			|> Player.reward(earnings)
		end
	end
	
	
	defp _deal(players, deck, updated, number) when length(updated) < number do
		player = List.first(players)
		{hand, remaining} = Deck.deal(deck, 2)
		_deal(players -- [player], remaining, updated ++ [{player, hand}], number)
	end
	defp _deal(_, deck, updated, _), do: {deck, updated}
end