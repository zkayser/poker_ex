defmodule PokerEx.HandServer do
	use GenServer
	alias PokerEx.Deck
	alias PokerEx.Hand
	alias PokerEx.Evaluator
	alias PokerEx.HandServer, as: Server
	
	@name :hand_server
	
	defstruct player_hands: [], table: [], deck: [], stats: []

	def start_link do
		GenServer.start_link(__MODULE__, [], name: @name)
	end
	
	#######################
	# Interface functions #
	#######################
	
	def deal_first_hand(players) do
		GenServer.call(@name, {:deal_first_hand, players})
	end
	
	def deal_flop do
		GenServer.call(@name, :deal_flop)
	end
	
	def deal_one do
		GenServer.call(@name, :deal_one)
	end
	
	def score do
		GenServer.call(@name, :score)
	end

	def hand_rankings do
		GenServer.call(@name, :hand_rankings)
	end
	
	def clear do
		GenServer.cast(@name, :clear)
	end
	
	def fetch_data do
		GenServer.call(@name, :fetch_data)
	end
	
	#############
	# Callbacks #
	#############
	
	def init([]) do
		{:ok, %Server{}}
	end
	
	def handle_call({:deal_first_hand, players}, _from, _server) do
		deck = Deck.new |> Deck.shuffle
		{updated_deck, updated_players} = deal(players, deck, [], length(players))
		server = %Server{player_hands: updated_players, deck: updated_deck}
		{:reply, server, server}
	end
	
	def handle_call(:deal_flop, _from, %Server{deck: deck, table: []} = server) do
		{flop, remaining} = Deck.deal(deck, 3)
		update = %Server{ server | table: flop, deck: remaining}
		{:reply, update, update}
	end
	
	def handle_call(:deal_one, _from, %Server{deck: deck, table: table} = server) when length(table) < 5 do
		{card, remaining} = Deck.deal(deck, 1)
		update = %Server{ server | table: table ++ card}
		{:reply, update, update}
	end
	
	def handle_call(:score, _from, %Server{player_hands: hands, table: table} = server) do
		evaluated = Enum.map(hands, fn {player, hand} -> {player, Evaluator.evaluate_hand(hand, table)} end)
		
		stats = Enum.map(evaluated, fn {player, hand} -> {player, hand.score} end)
		
		update = %Server{ server | player_hands: evaluated, stats: stats}
		{:reply, update, update}
	end
	
	def handle_call(:hand_rankings, _from, %Server{stats: stats} = server) do
		{:reply, stats, server}
	end
	
	def handle_call(:fetch_data, _from, server) do
		{:reply, server, server}
	end
	
	def handle_cast(:clear, _server) do
		{:noreply, %Server{}}
	end
	
	#####################
	# Utility Functions #
	#####################
	
	defp deal(players, deck, updated, number) when length(updated) < number do
		player = List.first(players)
		{hand, remaining} = Deck.deal(deck, 2)
		deal(players -- [player], remaining, updated ++ [{player, hand}], number)
	end
	defp deal(_, deck, updated, _), do: {deck, updated}
end