defmodule PokerEx.HandServer do
	use GenServer
	alias PokerEx.Deck
	alias PokerEx.Evaluator
	alias PokerEx.HandServer, as: Server
	alias PokerEx.Events
	
	defstruct player_hands: [], table: [], deck: [], stats: []

	def start_link do
		GenServer.start_link(__MODULE__, [])
	end
	
	#######################
	# Interface functions #
	#######################
	
	def deal_first_hand(pid, players) do
		GenServer.call(pid, {:deal_first_hand, players})
	end
	
	def deal_flop(pid) do
		GenServer.call(pid, :deal_flop)
	end
	
	def deal_one(pid) do
		GenServer.call(pid, :deal_one)
	end
	
	def player_hands(pid) do
		GenServer.call(pid, :player_hands)
	end
	
	def score(pid) do
		GenServer.call(pid, :score)
	end
	
	def fold(pid, player) do
		GenServer.cast(pid, {:fold, player})
	end

	def hand_rankings(pid) do
		GenServer.call(pid, :hand_rankings)
	end
	
	def clear(pid) do
		GenServer.cast(pid, :clear)
	end
	
	def fetch_data(pid) do
		GenServer.call(pid, :fetch_data)
	end
	
	def table(pid) do
		GenServer.call(pid, :table)
	end
	
	def stats(pid) do
		GenServer.call(pid, :stats)
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
		Events.flop_dealt(flop)
		{:reply, update, update}
	end
	
	def handle_call(:deal_one, _from, %Server{deck: deck, table: table} = server) when length(table) < 5 do
		{card, remaining} = Deck.deal(deck, 1)
		update = %Server{ server | table: table ++ card, deck: remaining}
		Events.card_dealt(card)
		{:reply, card, update}
	end
	
	def handle_call(:deal_one, _, _), do: raise "Only 5 cards can be dealt on the table"
	
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
	
	def handle_call(:player_hands, _from, %Server{player_hands: player_hands} = server) do
		{:reply, player_hands, server}
	end
	
	def handle_call(:table, _from, %Server{table: table} = server) do
		{:reply, table, server}
	end
	
	def handle_call(:stats, _from, %Server{stats: stats} = server) do
		{:reply, stats, server}
	end
	
	def handle_cast({:fold, player}, %Server{player_hands: player_hands} = server) do
		update = Enum.reject(player_hands, fn {name, _hand} -> name == player end)
		{:noreply, %Server{ server | player_hands: update}}
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