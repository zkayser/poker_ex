defmodule PokerEx.PlayersChannel do
	use Phoenix.Channel
	alias PokerEx.AppState
	alias PokerEx.Player
	alias PokerEx.Room
	# alias PokerEx.Presence  -> Implement presence tracking logic later
	
	intercept ["new_msg"]

	def join("players:lobby", message, socket) do
		send(self(), {:after_join, message})

		{:ok, %{}, socket}
	end
	def join("players:" <> room_id, params, socket) do
		send(self(), {:after_join_room, room_id, params})
		players = room_id |> atomize() |> Room.player_list()
		{:ok, %{players: players}, socket}
	end
	
	def handle_info({:after_join, _message}, socket) do
		player = socket.assigns.player_name
		broadcast! socket, "welcome_player", %{player: player}
		
		# The code below is from when the app was limited to a single
		# table that was joined upon signup. That is no longer the case,
		# but I am keeping this around for reference later when the client 
		# side gets readjusted.
		
		# Seating sends back a list of tuples that need to be
		# encoded to send with Poison. Break this out to a separate
		# module later.
		#seating = 
		#	case Room.state.seating do
		#		s when is_list(s) -> Enum.map(s, fn {name, pos} -> %{name: name, position: pos} end)
		#		[] -> nil
		#		{name, pos} -> %{name: name, position: pos} 
		#	end
		#broadcast! socket, "player_joined", %{player: player, seating: seating}
		#case Room.join(player) do
		#	{:game_begin, _, active, hands} ->
		#		send(self(), {:game_begin, hd(active), hands})
		#	_ ->
		#		:ok
		#end
		{:noreply, socket}
	end
	
	def handle_info({:after_join_room, room_id, _params}, socket) do
		socket = assign(socket, :room, room_id)
		IO.puts "Socket assigns: #{inspect(socket.assigns)}"
		player = Player.new(socket.assigns.player_name) |> AppState.put()
		room_id
		|> atomize()
		|> Room.join(player)
		
		players = room_id |> atomize() |> Room.player_list()
		
		seating = 
			case Room.state(room_id |> atomize()).seating do
				s when is_list(s) -> Enum.map(s, fn {name, pos} -> %{name: name, position: pos} end)
				[] -> nil
				{name, pos} -> %{name: name, position: pos} 
			end
		broadcast! socket, "player_joined", %{player: player, seating: seating}
		case Room.join(room_id |> atomize(), player) do
			{:game_begin, _, active, hands} ->
				send(self(), {:game_begin, hd(active), hands})
			_ ->
				:ok
		end
		
		broadcast! socket, "room_joined", %{player: player, players: players, room_id: room_id}

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
	
	#def terminate(_message, socket) do
	
	# Also a remnant of earlier design
	#	player = socket.assigns.player_name
	#	player = AppState.get(player)
	#	AppState.delete(player)
	#	Room.leave(player)
	#	broadcast! socket, "player_left", %{body: player}
	#	{:shutdown, :left}
	#end
	
	
	#####################
	# Utility functions #
	#####################
	
	defp atomize(str) when is_binary(str), do: String.to_atom(str)
	defp atomize(_), do: :error
end