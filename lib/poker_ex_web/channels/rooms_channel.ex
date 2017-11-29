defmodule PokerExWeb.RoomsChannel do
	use Phoenix.Channel
	require Logger
	alias PokerEx.Repo
	alias PokerEx.Player
	alias PokerEx.Room
	
	@valid_params ~w(player amount)
	@actions ~w(raise call check fold leave add_chips)
	
	def join("rooms:" <> room_title, %{"type" => type, "amount" => amount}, socket) when amount >= 100 do
		unless socket.assigns |> Map.has_key?(:player) do
			socket = 
				assign(socket, :room, atomize(room_title))
				|> assign(:type, type)
				|> assign(:join_amount, amount)
				|> assign_player()
	
			send self(), :after_join
			Logger.debug "Player #{socket.assigns.player.name} has joined room #{room_title}"
			{:ok, %{name: socket.assigns.player.name}, socket}
		end
	end
	
	def join("rooms:" <> _, _, _socket), do: {:error, %{message: "Could not join the room. Please try again."}}
	
	############
	# INTERNAL #
	############

	def handle_info(:after_join, %{assigns: assigns} = socket) do
		room = Room.join(assigns.room, assigns.player, assigns.join_amount)
		broadcast!(socket, "update", PokerExWeb.RoomView.render("room.json", %{room: room}))
		{:noreply, socket}
	end
	
	############
	# INCOMING #
	############
	
	def handle_in("action_" <> action, %{"player" => _player} = params, socket) when action in @actions do
		{player, params} = get_player_and_strip_params(params)
		case Enum.all?(Map.keys(params), &(&1 in @valid_params)) do
			true -> 
				room = apply(Room, atomize(action), [socket.assigns.room, player|Map.values(params)])
				maybe_broadcast_update(room, socket)
			_ -> {:error, :bad_room_arguments, Map.values(params)}
		end
		{:noreply, socket}
	end

	def handle_in("get_bank", %{"player" => player}, socket) do
		case Player.chips(player) do
			{:error, _} -> :error
			res -> 	push socket, "bank_info", %{chips: res}
		end
		{:noreply, socket}
	end

	def handle_in("chat_msg", %{"player" => player, "message" => message}, socket) do
		broadcast!(socket, "new_chat_msg", %{player: player, message: message})
		{:noreply, socket}
	end
	
	#############
	# TERMINATE #
	#############
	
	def terminate(reason, socket) do
		Logger.debug "[RoomChannel] Terminating with reason: #{inspect reason}"
		
		room = Room.leave(socket.assigns.room, socket.assigns.player)
		broadcast!(socket, "update", PokerExWeb.RoomView.render("room.json", %{room: room}))
		
		{:shutdown, :left}
	end
	
	####################
	# HELPER FUNCTIONS #
	####################

	defp atomize(room_title), do: String.to_atom(room_title)

	defp assign_player(socket) do
		player = Repo.get(Player, socket.assigns[:player_id])
		assign(socket, :player, player)
	end
	
	defp get_player_and_strip_params(%{"player" => player} = params) do
		{Player.by_name(player), Map.drop(params, ["player"])}
	end
	
	defp maybe_broadcast_update(:skip_update_message, _), do: :ok
	defp maybe_broadcast_update(room, socket) do
		broadcast!(socket, "update", PokerExWeb.RoomView.render("room.json", %{room: room}))
	end
end