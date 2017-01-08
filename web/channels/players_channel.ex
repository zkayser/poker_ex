defmodule PokerEx.PlayersChannel do
	use Phoenix.Channel
	alias PokerEx.AppState
	alias PokerEx.Player
	alias PokerEx.Room
	# alias PokerEx.Presence  -> Implement presence tracking logic later
	
	intercept ["new_msg"]

	def join("players:lobby", message, socket) do
		players = AppState.players
		send(self, {:after_join, message})

		{:ok, %{players: players},socket}
	end
	def join("players:" <> room_id, params, socket) do
		send(self, {:after_join_room, room_id, params})
		{:ok, %{}, socket}
	end
	
	def handle_info({:after_join, _message}, socket) do
		player_id = socket.assigns.player_name
		player = Player.new(player_id) |> AppState.put
		assign(socket, :player, player)
		# Seating sends back a list of tuples that need to be
		# encoded to send with Poison. Break this out to a separate
		# module later.
		IO.inspect Room.seating
		seating = case Room.seating do
			s when is_list(s) -> Enum.map(s, fn {name, pos} -> %{name: name, position: pos} end)
			[] -> nil
			{name, pos} -> %{name: name, position: pos} 
		end
		broadcast! socket, "player_joined", %{player: player, seating: seating}
		case Room.join(player) do
			{:game_begin, _, active, hands} ->
				send(self, {:game_begin, hd(active), hands})
			_ ->
				:ok
		end
		{:noreply, socket}
	end
	
	def handle_info({:after_join_room, room_id, params}, socket) do
		assign(socket, :room, room_id)
		IO.puts "after_join_room called with room_id: #{room_id}"
		broadcast! socket, "room_joined", %{room: room_id}
		{:noreply, socket}
	end
	
	def handle_info({:game_begin, {player, _seat}, hands}, socket) do
		hands = Enum.map(hands, 
			fn {name, hand} -> 
				cards = Enum.map(hand, fn card -> Map.from_struct(card) end)
				%{player: name, hand: cards}
			end)
		broadcast! socket, "game_began", %{active: player, hands: hands}
		{:noreply, socket}
	end
	
	#####################
	# INCOMING MESSAGES #
	#####################
	
	def handle_in("new_msg", %{"body" => body}, socket) do
		broadcast! socket, "new_msg", %{body: body}
		{:noreply, socket}
	end
	
	def handle_in("player_raised", %{"amount" => amount, "player" => player}, socket) do
		{amount, _} = Integer.parse(amount)
		Room.raise(AppState.get(player), amount)
		{:noreply, socket}
	end
	
	def handle_in("player_called", %{"player" => player}, socket) do
		Room.call(AppState.get(player))
		{:noreply, socket}
	end
	
	def handle_in("player_folded", %{"player" => player}, socket) do
		Room.fold(AppState.get(player))
		{:noreply, socket}
	end
	
	def handle_in("player_checked", %{"player" => player}, socket) do
		Room.check(AppState.get(player))
		{:noreply, socket}
	end
	
	#####################
	# Outgoing Messages #
	#####################
	
	def handle_out("new_msg", payload, socket) do
		push socket, "new_msg", payload
		{:noreply, socket}
	end
	
	#############
	# Terminate #
	#############
	
	def terminate(_message, socket) do
		player = socket.assigns.player_name
		player = AppState.get(player)
		AppState.delete(player)
		broadcast! socket, "player_left", %{body: player}
		{:shutdown, :left}
	end
end