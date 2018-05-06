defmodule PokerEx.GamesChannelTest do
  use PokerExWeb.ChannelCase
  import PokerEx.TestHelpers
  alias PokerExWeb.GamesChannel
  alias PokerEx.GameEngine, as: Game
  alias PokerEx.GameEngine.GamesSupervisor

  @endpoint PokerExWeb.Endpoint
  @registry Registry.Games
  @default_chips 500

  setup do
    title = "game_#{Base.encode16(:crypto.strong_rand_bytes(8))}"
    {:ok, _} = GamesSupervisor.find_or_create_process(title)
    [{game_pid, _}] = Registry.lookup(@registry, title)

    {socket, player, token, reply} = create_player_and_connect(title)
    @endpoint.subscribe("games:#{title}")

    {:ok,
     socket: socket, player: player, token: token, reply: reply, title: title, game_pid: game_pid}
  end

  test "authentication works", context do
    assert {:player_id, context.player.id} in context.socket.assigns
  end

  test "game join", context do
    for key <- [:join_amount, :player, :type, :game] do
      assert key in Map.keys(context.socket.assigns)
    end

    seated_players = for {player, _pos} <- get_game_state(context).seating.arrangement, do: player

    assert context.player.name in seated_players
    # Need to get a pid to pass to this
    # assert :sys.get_state().phase == :idle
  end

  test "a game starts when a second player joins", context do
    {_, player, _, _} = create_player_and_connect(context.title)

    game_state = get_game_state(context)
    seated_players = for {player, _} <- game_state.seating.arrangement, do: player

    for player <- [context.player.name, player.name], do: assert(player in seated_players)

    assert_broadcast("update", %{
      active: _,
      chip_roll: %{},
      paid: %{},
      player_hands: [
        %{hand: [%{rank: _, suit: _}, %{rank: _, suit: _}], player: _},
        %{hand: [%{rank: _, suit: _}, %{rank: _, suit: _}], player: _}
      ],
      players: [%{chips: _, name: _}, %{chips: _, name: _}],
      pot: 15,
      round: %{},
      seating: [%{name: _, position: _}, %{name: _, position: _}],
      table: [],
      to_call: 10,
      type: "public"
    })

    assert get_game_state(context).phase == :pre_flop
  end

  test "channel broadcasts actions taken by players", context do
    {_, player, _, _} = create_player_and_connect(context.title)
    player_name = player.name
    player_one = context.player.name

    active_player = get_game_state(context).player_tracker.active |> hd()
    assert active_player == player_name

    push(context.socket, "action_raise", %{"player" => player_name, "amount" => 25})

    assert_broadcast("update", %{active: ^player_one, pot: 40})

    push(context.socket, "action_call", %{"player" => player_one})

    assert_broadcast("update", %{active: ^player_name, pot: 60})

    push(context.socket, "action_check", %{"player" => player_name})

    assert_broadcast("update", %{active: ^player_one, pot: 60})

    push(context.socket, "action_check", %{"player" => player_one})

    push(context.socket, "action_raise", %{"player" => player_name, "amount" => 50})

    assert_broadcast("update", %{active: ^player_one, pot: 110})

    push(context.socket, "action_fold", %{"player" => player_one})

    assert_broadcast("update", %{state: "pre_flop"})

    assert_broadcast("winner_message", %{message: _})

    assert_broadcast("game_finished", %{message: _})
  end

  test "a new update message is broadcast when a player manually sends a leave message",
       context do
    {_, player, _, _} = create_player_and_connect(context.title)

    # Use :sys.get_state/1
    seating = get_game_state(context).seating.arrangement
    assert length(seating) == 2
    assert get_game_state(context).phase == :pre_flop

    expected_player_remaining = context.player.name

    push(context.socket, "action_leave", %{"player" => player.name})

    assert_broadcast("update", %{seating: [%{name: ^expected_player_remaining, position: 0}]})

    Process.sleep(100)
    seating_after_leave = get_game_state(context).seating.arrangement
    assert length(seating_after_leave) == 1
  end

  test "a new update message is broadcast when a player's channel is disconnected", context do
    {_, player, _, _} = create_player_and_connect(context.title)

    # Since a :skip_update_message is returned if there are only two players
    # and one leaves/gets disconnected (leaving only one player at the table), I'm having a
    # third player join here to invoke what would normally be returned given an ongoing game with
    # more than two players.

    {_, other_player, _, _} = create_player_and_connect(context.title)

    assert length(get_game_state(context).seating.arrangement) == 3
    assert get_game_state(context).phase == :pre_flop

    leave(context.socket)

    Process.sleep(100)
    assert context.player.name in get_game_state(context).async_manager.cleanup_queue
  end

  test "when there are only two players and one leaves, the channel broadcasts a 'clear_ui' message",
       context do
    {socket, player, _, _} = create_player_and_connect(context.title)

    assert length(get_game_state(context).seating.arrangement) == 2

    leave(socket)

    Process.sleep(100)
    assert_broadcast("clear_ui", %{})
  end

  test "the channel issues a push with the number of available chips when receiving a 'get_bank' message",
       context do
    push(context.socket, "get_bank", %{"player" => context.player.name})

    chips = PokerEx.Player.chips(context.player.name)

    assert_push("bank_info", %{chips: ^chips})
  end

  test "the channel broadcasts an update when a player submits an add_chips action", context do
    create_player_and_connect(context.title)

    player_name = context.player.name
    push(context.socket, "action_add_chips", %{"player" => player_name, "amount" => 200})

    Process.sleep(100)
    chips = get_game_state(context).chips.chip_roll[player_name]

    assert_broadcast("update", %{chip_roll: %{^player_name => ^chips}})
  end

  test "the channel broadcasts `new_chat_msg` in response to `chat_msg` incoming messages",
       context do
    create_player_and_connect(context.title)

    player_name = context.player.name
    message = "What's up y'all?"
    push(context.socket, "chat_msg", %{"player" => context.player.name, "message" => message})

    assert_broadcast("new_chat_msg", %{player: ^player_name, message: ^message})
  end

  defp create_player_and_connect(title) do
    player = insert_user()

    token = Phoenix.Token.sign(socket(), "user socket", player.id)

    {:ok, socket} = connect(PokerExWeb.UserSocket, %{"token" => token})

    {:ok, reply, socket} =
      subscribe_and_join(socket, GamesChannel, "games:#{title}", %{
        "type" => "public",
        "amount" => @default_chips
      })

    {socket, player, token, reply}
  end

  defp get_game_state(%{game_pid: pid}) do
    :sys.get_state(pid)
  end
end
