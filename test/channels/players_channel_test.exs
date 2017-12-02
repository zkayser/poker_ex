defmodule PokerEx.PlayersChannelTest do
	use PokerExWeb.ChannelCase
	import PokerEx.TestHelpers
	alias PokerExWeb.PlayersChannel
	alias PokerEx.Player

	@endpoint PokerExWeb.Endpoint

	setup do
		{socket, player, token, reply} = create_player_and_connect(%{auth_type: :valid_auth})

		{:ok, socket: socket, player: player, token: token, reply: reply}
	end

	test "join replies with ':success' if authentication is successful", context do
		assert context.reply.response == :success
	end

	test "join replies with a failure message if authentication fails with existing players", _ do
		{_, _, _, reply} = create_player_and_connect(%{auth_type: :existing_player_invalid_auth})

		assert reply == %{message: "Authentication failed"}
	end

	test "join replies with a failure message if authentication fails with non-existent players", _ do
		{_, _, _, reply} = create_player_and_connect(%{auth_type: :non_existent_player})

		assert reply == %{message: "Authentication failed"}
	end

	test "the channel pushes the client a `chip_info` message with chips in response to `get_chip_count` msgs", context do
		push context.socket, "get_chip_count", %{}

		chips = Player.chips(context.player.name)

		assert_push "chip_info", %{chips: ^chips}
	end

	defp create_player_and_connect(%{auth_type: auth_type}) do
		player = insert_user()
		name = 
			case auth_type do
				:valid_auth -> player.name
				:existing_player_invalid_auth -> insert_user().name
				:non_existent_player -> "non_existent_player"
			end

		token = Phoenix.Token.sign(socket(), "user socket", player.id)

		{:ok, socket} = connect(PokerExWeb.UserSocket, %{"token" => token})

		with {:ok, reply, socket} <- subscribe_and_join(socket, PlayersChannel, "players:" <> name) do
			{socket, player, token, reply}
		else {:error, reply} -> {socket, player, token, reply}
		end 
	end

end