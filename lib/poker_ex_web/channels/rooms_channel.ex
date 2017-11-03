defmodule PokerExWeb.RoomsChannel do
	use Phoenix.Channel
	require Logger
	alias PokerEx.Repo
	alias PokerEx.Player
	alias PokerEx.Room
	
	@valid_params ~w(player amount)
	
	def join("rooms:" <> room_title, %{"type" => type, "amount" => amount}, socket) do
		socket = 
			assign(socket, :room, atomize(room_title))
			|> assign(:type, type)
			|> assign(:join_amount, amount)
			|> assign_player()

		send self(), {:after_join, type}

		{:ok, %{name: socket.assigns.player.name}, socket}
	end
	
	############
	# INTERNAL #
	############

	def handle_info({:after_join, _room_type}, %{assigns: assigns} = socket) do
		Room.join(assigns.room, assigns.player, assigns.join_amount)
		{:noreply, socket}
	end
	
	############
	# INCOMING #
	############
	
	def handle_in("action_" <> action, %{"player" => player} = params, socket) when action in ["raise", "call", "check", "fold"] do
		{player, params} = get_player_and_strip_params(params)
		case Enum.all?(Map.keys(params), &(&1 in @valid_params)) do
			true -> 
				room = apply(Room, atomize(action), [socket.assigns.room, player|Map.values(params)])
				broadcast!(socket, "update", PokerExWeb.RoomView.render("room.json", %{room: room}))
			_ -> {:error, :bad_room_arguments, Map.values(params)}
		end
		{:noreply, socket}
	end

	defp atomize(room_title) do
		String.to_atom(room_title)
	end

	defp assign_player(socket) do
		player = Repo.get(Player, socket.assigns[:player_id])
		assign(socket, :player, player)
	end
	
	defp get_player_and_strip_params(%{"player" => player} = params) do
		{Player.by_name(player), Map.drop(params, ["player"])}
	end
end