defmodule PokerExWeb.PlayersChannel do
	require Logger
	use Phoenix.Channel
	alias PokerEx.Player
	
	def join("players:" <> player_name, _params, socket) do
		with %Player{} = player <- Player.by_name(player_name) do
			case player.id == socket.assigns.player_id do
				true -> {:ok, %{response: :success}, assign(socket, :player, player)}
				false -> {:error, %{message: "Authentication failed"}}
			end
		else _ -> {:error, %{message: "Authentication failed"}}
		end
	end

	#####################
	# INCOMING MESSAGES #
	#####################

	def handle_in("get_chip_count", _params, socket) do
		push socket, "chip_info", %{chips: Player.chips(socket.assigns.player.name)}
		{:noreply, socket}
	end
end