defmodule PokerExWeb.PlayersChannel do
	require Logger
	use Phoenix.Channel
	alias PokerEx.Player

	@updatable_attributes ~w(email blurb chips)

	def join("players:" <> player_name, _params, socket) do
		with %Player{} = player <- Player.by_name(player_name) do
			case player.id == socket.assigns.player_id do
				true ->
					send self(), %{update_for: player.id}
					{:ok, %{response: :success}, assign(socket, :player, player)}
				false -> {:error, %{message: "Authentication failed"}}
			end
		else _ -> {:error, %{message: "Authentication failed"}}
		end
	end

	def handle_info(%{update_for: id}, socket) when is_number(id) do
		with %Player{} = player <- Player.get(id) do
			push socket, "player", Phoenix.View.render_one(player, PokerExWeb.PlayerView, "player.json")
		else
			_ -> {:error, "update failed"}
		end
		{:noreply, socket}
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

	def handle_in("update_player", %{"chips" => 1000} = params, socket) do
		handle_update_player(params, socket)
		{:noreply, socket}
	end

	def handle_in("update_player", params, socket) do
		case Enum.all?(Map.keys(params), &(&1 in @updatable_attributes)) do
			true -> handle_update_player(params, socket)
			false ->
				push socket, "error", %{error: "Failed to update attributes: #{inspect Map.keys(params)}"}
		end
		{:noreply, socket}
	end

	def handle_in("get_chip_count", _params, socket) do
		push socket, "chip_info", %{chips: Player.chips(socket.assigns.player.name)}
		{:noreply, socket}
	end

	####################
	# HELPER FUNCTIONS #
	####################
	defp handle_update_player(params, socket) do
		with %Player{} = player <- Player.get(socket.assigns.player_id) do
			changeset = Player.update_changeset(player, params)
			case PokerEx.Repo.update(changeset) do
				{:ok, player} ->
					push socket, "player", Phoenix.View.render_one(player, PokerExWeb.PlayerView, "player.json")
					for attr <- Map.keys(params) do
					 push socket, "attr_updated", %{message: "#{String.capitalize(attr)} successfully updated"}
					end
				{:error, changeset} ->
					push socket, "error", %{error: changeset.errors}
			end
		else
			_ -> push socket, "error", %{error: "Failed to update attributes: #{inspect Map.keys(params)}"}
		end
	end
end