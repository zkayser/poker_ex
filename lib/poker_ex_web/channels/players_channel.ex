defmodule PokerExWeb.PlayersChannel do
	require Logger
	use Phoenix.Channel
	alias PokerEx.Player

	@updatable_attributes ~w(email blurb chips)

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

	def handle_in("get_player", _params, socket) do
		with %Player{} = player <- Player.get(socket.assigns.player_id) do
			push socket, "player", Phoenix.View.render_one(player, PokerExWeb.PlayerView, "player.json")
		else
			_ -> push socket, "error", %{error: "Failed to retrieve player"}
		end
		{:noreply, socket}
	end

	def handle_in("update_player", %{"chips" => 1000}, socket) do

		{:noreply, socket}
	end

	def handle_in("update_player", params, socket) do
		case Enum.all?(Map.keys(params), &(&1 in @updatable_attributes)) do
			true ->
				with %Player{} = player <- Player.get(socket.assigns.player_id) do
					changeset = Player.update_changeset(player, params)
					case PokerEx.Repo.update(changeset) do
						{:ok, player} ->
							push socket, "player", Phoenix.View.render_one(player, PokerExWeb.PlayerView, "player.json")
						{:error, changeset} ->
							push socket, "error", %{error: changeset.errors}
					end
				else
					_ -> push socket, "error", %{error: "Failed to update attributes: #{inspect Map.keys(params)}"}
				end
			false ->
				push socket, "error", %{error: "Failed to update attributes: #{inspect Map.keys(params)}"}
		end
		{:noreply, socket}
	end

	def handle_in("get_chip_count", _params, socket) do
		push socket, "chip_info", %{chips: Player.chips(socket.assigns.player.name)}
		{:noreply, socket}
	end
end