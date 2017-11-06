defmodule PokerExWeb.RoomsChannel do
	use Phoenix.Channel
	require Logger
	alias PokerEx.Repo
	alias PokerEx.Player
	alias PokerEx.Room
	
	@valid_params ~w(player amount)
	
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
		
		json = PokerExWeb.RoomView.render("room.json", %{room: room})
		Logger.debug "Update has been sent with the following data:\n #{inspect json}"
		{:noreply, socket}
	end
	
	############
	# INCOMING #
	############
	
	def handle_in("action_" <> action, %{"player" => _player} = params, socket) when action in ["raise", "call", "check", "fold"] do
		{player, params} = get_player_and_strip_params(params)
		case Enum.all?(Map.keys(params), &(&1 in @valid_params)) do
			true -> 
				room = apply(Room, atomize(action), [socket.assigns.room, player|Map.values(params)])
				broadcast!(socket, "update", PokerExWeb.RoomView.render("room.json", %{room: room}))
			_ -> {:error, :bad_room_arguments, Map.values(params)}
		end
		{:noreply, socket}
	end
	
	####################
	# HELPER FUNCTIONS #
	####################

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