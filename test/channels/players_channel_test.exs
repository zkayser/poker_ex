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

  test "join replies with a failure message if authentication fails with non-existent players",
       _ do
    {_, _, _, reply} = create_player_and_connect(%{auth_type: :non_existent_player})

    assert reply == %{message: "Authentication failed"}
  end

  test "a `player` update message is sent after joining", context do
    player_json = Phoenix.View.render_one(context.player, PokerExWeb.PlayerView, "player.json")

    assert_push("player", ^player_json)
  end

  test "the channel pushes the client a `chip_info` message with chips in response to `get_chip_count` msgs",
       context do
    push(context.socket, "get_chip_count", %{})

    chips = Player.chips(context.player.name)

    assert_push("chip_info", %{chips: ^chips})
  end

  test "the channel pushes `player` messages to the client in response to `get_player` msgs",
       context do
    push(context.socket, "get_player", %{player: context.player.name})

    player_json = Phoenix.View.render_one(context.player, PokerExWeb.PlayerView, "player.json")

    assert_push("player", ^player_json)
  end

  test "the channel pushes `player` messages to the client in response to `update_player` msgs",
       context do
    new_email = "the_real_player#{Base.encode16(:crypto.strong_rand_bytes(8))}@email.com"

    push(context.socket, "update_player", %{email: new_email})

    Process.sleep(50)
    player = Player.get(context.player.id)
    player_json = Phoenix.View.render_one(player, PokerExWeb.PlayerView, "player.json")

    # Verify that the update was valid
    assert player.email == new_email
    assert_push("player", ^player_json)
    assert_push("attr_updated", %{message: "Email successfully updated"})
  end

  test "the channel pushes an `error` message if an invalid attribute is given in `update_player`",
       context do
    push(context.socket, "update_player", %{some_bad_attr: "blah"})

    assert_push("error", %{error: "Failed to update attributes: [\"some_bad_attr\"]"})
  end

  test "`player_search` messages trigger a response push with `player_search_list`", context do
    # Most test player data should have 'user' in :name
    push(context.socket, "player_search", %{query: "user"})

    assert_push("player_search_list", %{players: _})
  end

  test "`delete_profile` messages should reply send a reply if deleting the current player",
       context do
    ref = push(context.socket, "delete_profile", %{"player" => context.player.name})

    assert_reply(ref, :ok)

    assert Player.get(context.player.id) == {:error, :player_not_found}
  end

  test "`delete_profile` returns an error if it receives a player param != to socket.player",
       context do
    ref = push(context.socket, "delete_profile", %{"player" => "bobbadeedoo"})

    assert_reply(ref, :error)

    assert Player.get(context.player.id).id == context.player.id
  end

  defp create_player_and_connect(%{auth_type: auth_type}) do
    player = insert_user()

    name =
      case auth_type do
        :valid_auth -> player.name
        :existing_player_invalid_auth -> insert_user().name
        :non_existent_player -> "non_existent_player"
      end

    token = Phoenix.Token.sign(socket(PokerExWeb.UserSocket), "user socket", player.id)

    {:ok, socket} = connect(PokerExWeb.UserSocket, %{"token" => token})

    with {:ok, reply, socket} <- subscribe_and_join(socket, PlayersChannel, "players:" <> name) do
      {socket, player, token, reply}
    else
      {:error, reply} -> {socket, player, token, reply}
    end
  end
end
