defmodule PokerEx.PrivateRoomTest do
  use ExUnit.Case, async: false
  use PokerEx.ModelCase
  import PokerEx.TestHelpers
  alias PokerEx.PrivateRoom, as: PRoom
  alias PokerEx.GameEngine, as: Game
  alias PokerEx.Player
  alias PokerEx.Room

  setup do
    player = insert_user()

    invitees = for _ <- 1..4, do: insert_user()

    {:ok, room} =
      PRoom.create("game#{Base.encode16(:crypto.strong_rand_bytes(8))}", player, invitees)

    {:ok, player: player, invitees: invitees, room: room}
  end

  test "create/3 instantiates a new `PrivateRoom` instance", %{player: player} do
    title = "room_title#{Base.encode16(:crypto.strong_rand_bytes(8))}"
    invitees = for _ <- 1..4, do: insert_user()
    {:ok, room} = PRoom.create(title, player, invitees)

    assert room.owner == player
    assert room.invitees == invitees
    assert room.title == title
    # Player owns the room
    assert room.id in Enum.map(Player.preload(player).owned_rooms, & &1.id)
    # The owner is included in participants by default
    assert player in room.participants
    # Creates the room process
    assert PRoom.alive?(title)
  end

  test "accept_invitation/2 moves a player from the invitees list to `participants`", context do
    participant = hd(context.invitees)

    {:ok, room} = PRoom.accept_invitation(context.room, participant)

    assert participant in room.participants
    refute participant in room.invitees

    updated_participant = Player.get(participant.id)

    assert room.id in Enum.map(Player.preload(updated_participant).participating_rooms, & &1.id)
    refute room.id in Enum.map(Player.preload(updated_participant).invited_rooms, & &1.id)
  end

  test "decline_invitation/2 removes a player from the invitees list", context do
    declining_player = hd(context.invitees)

    {:ok, room} = PRoom.decline_invitation(context.room, declining_player)

    refute declining_player in room.invitees
  end

  test "leave_room/2 removes a player from the `participants` and `Room` instance if seated",
       context do
    leaving_player = hd(context.invitees)

    # First add some participants
    {:ok, room} = PRoom.accept_invitation(context.room, leaving_player)

    room_process = context.room.title

    Game.join(room_process, leaving_player, 200)

    # Ensure that the player successfully joined the room.
    assert leaving_player.name in Enum.map(
             Game.get_state(room_process).seating.arrangement,
             fn {pl, _} -> pl end
           )

    {:ok, room} = PRoom.leave_room(room, leaving_player)
    refute leaving_player in room.participants

    # Should also remove the player from the `Room` instance
    assert leaving_player.name in Game.get_state(room_process).async_manager.cleanup_queue
  end

  @tag :capture_log
  test "delete/1 deletes the `PrivateRoom` from the database and shuts down the `Room`",
       context do
    room_process = String.to_atom(context.room.title)

    {:ok, _} = PRoom.delete(context.room)

    assert Repo.get(PRoom, context.room.id) == nil

    # The room instance should also be shutdown (it will be nil)
    refute Process.whereis(room_process)
  end

  test "all/0 returns all of the PrivateRoom instances", _ do
    rooms = PRoom.all()
    assert is_list(rooms) && length(rooms) > 0
  end

  test "by_title/1 returns the PrivateRoom instance with that title or nil", context do
    assert PRoom.by_title(context.room.title).id == context.room.id
  end

  test "get_room_and_store_state/3 updates the PrivateRoom instance with current game state",
       context do
    room_process = context.room.title

    # The current game state will be :idle since no actions have been taken
    state = :idle
    # `Room.state/1 returns a `Room` instance representing the current game`
    data = Game.get_state(room_process)

    assert {:ok, _} = PRoom.get_room_and_store_state(room_process, state, data)

    # Let async DB update take place
    Process.sleep(50)

    room = PRoom.get(context.room.id)
    # The `state` and `data` are serialized to a binary format for storage.
    # `:erlang.binary_to_term/1` restores the binary form to its actual representation.
    assert :erlang.binary_to_term(room.room_state) == :idle
    assert :erlang.binary_to_term(room.room_data) == data
  end

  @tag :capture_log
  test "ensure_started/1 checks if a room process exists and creates one if not", context do
    room_process = context.room.title

    data = Game.get_state(room_process)
    Game.stop(room_process)

    assert PRoom.ensure_started(room_process) == data
  end

  test "is_owner?/2 returns true if the player param owns the room instance passed in", context do
    assert PRoom.is_owner?(context.player, context.room.title)
  end

  test "is_owner?/2 returns false if the player param does not own the room passed in", context do
    refute PRoom.is_owner?(hd(context.invitees), context.room.title)
  end
end
