defmodule PokerExWeb.RoomsChannel do
	use Phoenix.Channel
	require Logger
	alias PokerEx.Repo
	alias PokerEx.Player
	alias PokerEx.PrivateRoom
	alias PokerEx.Room

	@valid_params ~w(player amount)
	@actions ~w(raise call check fold leave add_chips)
	@poker_actions ~w(raise call check fold)
	@manual_join_msg "Welcome. Please join by pressing the join button and entering an amount."

	def join("rooms:" <> room_title, %{"type" => type, "amount" => amount}, socket) when amount >= 100 do
		unless socket.assigns |> Map.has_key?(:player) do
			socket =
				assign(socket, :room, room_title)
				|> assign(:type, type)
				|> assign(:join_amount, amount)
				|> assign_player()

			send self(), :after_join
			Logger.debug "Player #{socket.assigns.player.name} has joined room #{room_title}"
			{:ok, %{name: socket.assigns.player.name}, socket}
		end
	end

	# This is a private room join for players who are already seated. All public joins
	# should go through the function above, as well as the initial join to a private room.
	def join("rooms:" <> room_title, %{"type" => "private", "amount" => 0}, socket) do
		socket =
			assign(socket, :room, room_title)
			|> assign(:type, "private")
			|> assign(:join_amount, 0)
			|> assign_player()

		case socket.assigns.player.name in Enum.map(Room.state(socket.assigns.room).seating, fn {name, _} -> name end) do
			true ->
				send self(), :after_join
				Logger.debug "Player #{socket.assigns.player.name} is joining private room #{room_title}"
				{:ok, %{name: socket.assigns.player.name}, socket}
			false ->
				{:error, %{message: @manual_join_msg}}
		end
	end

	def join("rooms:" <> _, _, _socket), do: {:error, %{message: "Could not join the room. Please try again."}}

	############
	# INTERNAL #
	############

	def handle_info(:after_join, %{assigns: assigns} = socket) do
		seating = Enum.map(Room.state(assigns.room).seating, fn {name, _} -> name end)
		case {assigns.type == "private", assigns.player.name in seating} do
			{true, true} ->
				room = Room.state(assigns.room)
				broadcast!(socket, "update", PokerExWeb.RoomView.render("room.json", %{room: room}))
			{_, _} ->
				room = Room.join(assigns.room, assigns.player, assigns.join_amount)
				broadcast!(socket, "update", PokerExWeb.RoomView.render("room.json", %{room: room}))
		end
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
				save_private_room(room, socket)
				broadcast_action_message(player, action, params, socket)
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

		room =
		 case Room.state(socket.assigns.room).type do
		 	:private -> socket.assigns.room
		 	:public -> Room.leave(socket.assigns.room, socket.assigns.player)
		 end
		broadcast!(socket, "update", PokerExWeb.RoomView.render("room.json", %{room: room}))

		{:shutdown, :left}
	end

	####################
	# HELPER FUNCTIONS #
	####################

	defp atomize(string), do: String.to_atom(string)

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

	defp save_private_room(:skip_update_message, _), do: :ok
	defp save_private_room(room, socket) do
		case socket.assigns.type do
			"private" ->
				PrivateRoom.get_room_and_store_state(room.room_id, Room.which_state(room.room_id), room)
			_ -> :ok
		end
	end

	defp broadcast_action_message(player, action, params, socket) when action in @poker_actions do
		message =
			case action do
				"call" -> "#{player.name} called."
				"raise" -> "#{player.name} raised #{inspect params["amount"]}."
				"fold" -> "#{player.name} folded."
				"check" -> "#{player.name} checked."
			end

		broadcast!(socket, "new_message", %{message: message})
	end
	defp broadcast_action_message(_, _, _, _), do: :ok
end