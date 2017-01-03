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
	def join("players:" <> _private_room_id, _params, _socket) do
		{:error, %{reason: "unauthorized"}}
	end
	
	def handle_info({:after_join, _message}, socket) do
		player_id = socket.assigns.player_name
		player = Player.new(player_id) |> AppState.put
		assign(socket, :player, player)
		broadcast! socket, "player_joined", %{player: player}
		case Room.join(player) do
			{:game_begin, _, active, hands} ->
				send(self, {:game_begin, hd(active), hands})
			_ ->
				:ok
		end
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
	
	def handle_in("new_msg", %{"body" => body}, socket) do
		broadcast! socket, "new_msg", %{body: body}
		{:noreply, socket}
	end
	
	def handle_out("new_msg", payload, socket) do
		push socket, "new_msg", payload
		{:noreply, socket}
	end
	
	def terminate(_message, socket) do
		player = socket.assigns.player_name
		player = AppState.get(player)
		AppState.delete(player)
		broadcast! socket, "player_left", %{body: player}
		{:shutdown, :left}
	end
end