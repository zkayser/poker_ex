defmodule PokerExWeb.RoomsChannel do
	use Phoenix.Channel
	require Logger
	alias PokerEx.Repo
	alias PokerEx.Player
	alias PokerEx.Room
	
	def join("rooms:" <> room_title, %{"type" => type, "amount" => amount}, socket) do
		socket = 
			assign(socket, :room, atomize(room_title))
			|> assign(:type, type)
			|> assign(:join_amount, amount)
			|> assign_player()

		send self(), {:after_join, type}

		{:ok, %{name: socket.assigns.player.name}, socket}
	end

	def handle_info({:after_join, room_type}, %{assigns: assigns} = socket) do
		Room.join(assigns.room, assigns.player, assigns.join_amount)
		{:noreply, socket}
	end

	defp atomize(room_title) do
		String.to_atom(room_title)
	end

	defp assign_player(socket) do
		player = Repo.get(Player, socket.assigns[:player_id])
		assign(socket, :player, player)
	end
end