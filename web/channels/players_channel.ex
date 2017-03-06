defmodule PokerEx.PlayersChannel do
	require Logger
	use Phoenix.Channel
	alias PokerEx.Player
	alias PokerEx.Room
	alias PokerEx.Endpoint
	alias PokerEx.Repo
	alias PokerEx.PlayerView
	# alias PokerEx.Presence  -> Implement presence tracking logic later
	
	def join("players:lobby", message, socket) do
		send(self(), {:after_join, message})
		player_name = Repo.get(Player, socket.assigns[:player_id]).name
		{:ok, %{name: player_name}, socket}
	end
	def join("players:" <> room_id, %{"type" => "public"}, socket) do
		send(self(), {:after_join_room, room_id})
		socket = 
			socket 
			|> assign(:room_type, :public)
		players = room_id |> atomize() |> Room.player_list()
		{:ok, %{players: players}, socket}
	end
	def join("players:" <> room_id, %{"type" => "private"}, socket) do
		send(self(), {:after_join_private_room, room_id})
		socket = 
			socket
			|> assign(:room_type, :private)
		players = room_id |> atomize() |> Room.player_list()
		{:ok, %{players: players}, socket}
	end
	def join("players:" <> room_id, params, socket) do
		send(self(), {:after_join_room, room_id, params})
		players = room_id |> atomize() |> Room.player_list()
		{:ok, %{players: players}, socket}
	end
	
	def handle_info({:after_join, _message}, socket) do
		player = Repo.get(Player, socket.assigns[:player_id]).name
		broadcast! socket, "welcome_player", %{player: player}
		
		{:noreply, socket}
	end
	
	def handle_info({:after_join_room, room_id}, socket) do
		socket = assign(socket, :room, room_id)
		player = Repo.get(Player, socket.assigns[:player_id])
		socket = assign(socket, :player_name, player.name)
		room = Room.state(room_id |> atomize())
		
		push(socket, "private_room_join", PokerEx.RoomView.render("room.json", %{room: room}))
		{:noreply, socket}
	end
	
	def handle_info({:after_join_private_room, room_id}, socket) do
		socket = assign(socket, :room, room_id)
		player = Repo.get(Player, socket.assigns[:player_id])
		socket = assign(socket, :player_name, player.name)
		room = Room.state(room_id |> atomize())
	
		push(socket, "private_room_join", PokerEx.RoomView.render("room.json", %{room: room}))
		{:noreply, socket}
	end
	
	def handle_info({:game_begin, {player, _seat}, hands}, socket) do
		hands = Enum.map(hands, 
			fn {name, hand} -> 
				cards = Enum.map(hand, fn card -> Map.from_struct(card) end)
				%{player: name, hand: cards}
			end)
		Endpoint.broadcast("room:" <> socket.assigns.room, "game_began", %{active: player, hands: hands})
		{:noreply, socket}
	end
	
	def handle_info(:save_state, socket) do
		room = socket.assigns["room"]
		priv_room = Repo.get_by(PrivateRoom, title: room)
		room_state = Room.which_state(room |> atomize())
		room_data = Room.state(room |> atomize())
		PrivateRoom.store_state(priv_room, %{"room_state" => :erlang.term_to_binary(room_state), "room_data" =>:erlang.term_to_binary(room_data)})
		{:noreply, socket}
	end
	
	#####################
	# INCOMING MESSAGES #
	#####################
	
	def handle_in("get_num_players", _, socket) do
		for x <- 1..10 do
			room = :"room_#{x}"
			length = length(Room.state(room).seating)
			broadcast! socket, "update_num_players", %{room: room, length: length}
		end
		{:noreply, socket}
	end
	
	def handle_in("add_player", %{"player" => name, "room" => title, "amount" => amount} = params, socket) when amount >= 100 do
		if socket.assigns.room_type == :private, do: private_add_player(params, socket), else: public_add_player(params, socket)
	end
	def handle_in("add_player", _params, socket), do: {:noreply, socket}
	
	def handle_in("remove_player", %{"player" => name, "room" => room}, socket) do
		room = Room.leave(room |> atomize(), get_player_by_name(name))
		case length(room.seating) do
			x when x <= 1 ->
				broadcast!(socket, "clear", PokerEx.RoomView.render("room.json", %{room: room}))
				{:noreply, socket}
			_ ->
				broadcast!(socket, "update", PokerEx.RoomView.render("room.json", %{room: room}))
				{:noreply, socket}
		end
	end
	
	def handle_in("start_game", %{"room" => room_title}, socket) do
		room = room_title |> atomize()
		case length(Room.state(room).seating) > 1 do
			false -> 
				# Ignore request if seating <= 1
				{:noreply, socket}
			true ->
				room = Room.start(room)
				broadcast!(socket, "started_game", PokerEx.RoomView.render("room.json", %{room: room}))
				{:noreply, socket}
		end
	end
	
	def handle_in("chat_message", %{"input" => ""}, socket), do: {:noreply, socket} # Temporarily hack to get around disconnect/reconnects
	
	def handle_in("chat_message", %{"input" => input}, socket) do
		broadcast!(socket, "new_message", %{name: socket.assigns[:player_name], text: input})
		{:noreply, socket}
	end
	
	def handle_in("request_chips", %{"player" => player, "amount" => amount}, socket) do
		amount = String.to_integer(amount)
		case Player.subtract_chips(player, amount) do
			{:ok, struct} -> 
				room_title = socket.assigns.room |> atomize()
					Room.add_chips(room_title, player, amount)
					push(socket, "update_emblem_display", %{name: player, add: amount})
					push(socket, "update_bank_max", %{max: struct.chips})
					if Room.state(room_title).type == :private, do: send(:self, :save_state)
					{:noreply, socket}
			{:error, _} -> 
				push(socket, "failed_bank_update", %{})
				{:noreply, socket}
		end
	end
	
	def handle_in("player_raised", %{"amount" => amount, "player" => player}, socket) do
		{amount, _} = Integer.parse(amount)
		room = Room.raise(socket.assigns.room |> atomize(), get_player_by_name(player), amount)
		handle_update(socket, room)
	end
	
	def handle_in("player_called", %{"player" => player}, socket) do
		room = Room.call(socket.assigns.room |> atomize(), get_player_by_name(player))
		case room do
			%Room{} -> 
				handle_update(socket, room)
			_ ->
				{:noreply, socket}
		end
	end
	
	def handle_in("player_folded", %{"player" => player}, socket) do
		room = Room.fold(socket.assigns.room |> atomize(), get_player_by_name(player))
		case room do
			%Room{} -> 
				handle_update(socket, room)
			_ ->
				{:noreply, socket}
		end
	end
	
	def handle_in("player_checked", %{"player" => player}, socket) do
		room = Room.check(socket.assigns.room |> atomize(), get_player_by_name(player))
		case room do
			%Room{} -> 
				handle_update(socket, room)
			_ ->
				{:noreply, socket}
		end
	end
	
	# TODO: Implement "remove_player" message
	
	#############
	# Terminate #
	#############
	
	def terminate(_message, socket) do
		case socket.assigns[:room_type] do
			:private ->
				broadcast!(socket, "clear_table", %{player: Repo.get(Player, socket.assigns[:player_id]).name})
				{:shutdown, :left}
			_ ->
				room_id = socket.assigns[:room]
				player = Repo.get(Player, socket.assigns[:player_id])
				room =
					room_id
						|> atomize()
						|> Room.leave(player)
				broadcast! socket, "update", PokerEx.RoomView.render("room.json", %{room: room}) 
				{:shutdown, :left}	
		end
	end
	
	#####################
	# Utility functions #
	#####################
	
	defp atomize(str) when is_binary(str), do: String.to_atom(str)
	defp atomize(atom) when is_atom(atom), do: atom
	defp atomize(_), do: :error
	
	defp get_player_by_name(name) when is_binary(name) do
		Repo.get_by(Player, name: name)
	end
	defp get_player_by_name(_), do: :error
	
	defp handle_update(socket, %Room{type: :private} = room) do
		PokerEx.PrivateRoom.get_room_and_store_state(room.room_id, Room.which_state(room.room_id), room)
		broadcast!(socket, "update", PokerEx.RoomView.render("room.json", %{room: room}))
		{:noreply, socket}
	end
	defp handle_update(socket, room) do
		broadcast!(socket, "update", PokerEx.RoomView.render("room.json", %{room: room}))
		{:noreply, socket}
	end
	
	defp private_add_player(%{"player" => name, "room" => title, "amount" => amount} = params, socket) do
		case Repo.get_by(Player, name: name) do
			%Player{} = pl -> 
				private_room = Repo.get_by(PokerEx.PrivateRoom, title: title) |> PokerEx.PrivateRoom.preload()
				changeset = 
					PokerEx.PrivateRoom.changeset(private_room)
					|> PokerEx.PrivateRoom.remove_invitee(private_room.invitees, pl)
					|> PokerEx.PrivateRoom.put_invitee_in_participants(private_room.participants, pl)
				case Repo.update(changeset) do
					{:ok, _priv_room} -> 
						room = title |> atomize() |> Room.join(pl, amount)
						broadcast!(socket, "add_player_success", PokerEx.RoomView.render("room.json", %{room: room}))
						push socket, "join_room_success", %{name: pl.name, chips: (pl.chips - String.to_integer(amount))}
					{:error, reason} -> push socket, "error_on_room_join", %{reason: reason}
					_ -> push socket, "error_on_room_join", %{}
				end
			{:error, reason} -> push socket, "error_on_room_join", %{reason: reason}
			_ -> push socket, "error_on_room_join", %{}
		end
		{:noreply, socket}
	end
	
	defp public_add_player(%{"player" => name, "room" => room_id, "amount" => amount} = params, socket) do
		case Repo.get_by(Player, name: name) do
			%Player{} = pl ->
				room = room_id |> atomize() |> Room.join(pl, amount)
				broadcast!(socket, "add_player_success", PokerEx.RoomView.render("room.json", %{room: room}))
				push socket, "join_room_success", %{name: pl.name, chips: (pl.chips - amount)}
			{:error, reason} -> push socket, "error_on_room_join", %{reason: reason}
		end
		{:noreply, socket}
	end
end