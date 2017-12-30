defmodule PokerExWeb.PrivateRoomChannel do
	use Phoenix.Channel
	alias PokerEx.Player
	alias PokerEx.PrivateRoom

	def join("private_rooms:" <> player_name, _params, socket) do
		with %Player{} = player <- Player.by_name(player_name) do
			case player.id == socket.assigns.player_id do
				true ->
					send self(), %{rooms_for: player}
					{:ok, %{response: :success}, assign(socket, :player, player)}
				false -> {:error, %{message: "Authentication failed"}}
			end
		else _ -> {:error, %{message: "Authentication failed"}}
		end
	end

	def handle_info(%{rooms_for: %Player{} = player}, socket) do
		{:noreply, socket}
	end
end