defmodule PokerEx.GameEventsTest do
  use ExUnit.Case, async: true
  import PokerEx.TestHelpers
  alias PokerEx.GameEvents

  setup do
    player_1 = insert_user(username: "player_1")
    player_2 = insert_user(username: "player_2")
    seating_and_active = [{player_1.name, 0}, {player_2.name, 1}]
    chip_roll = %{player_1.name => 1000, player_2.name => 1000}
    table = fake_table_flop()
    attrs = %{seating: seating_and_active,
              active: seating_and_active,
              chip_roll: chip_roll,
              table: table,
              room_id: "room_1"
             }
    room = build_room(attrs)

    %{room: room}
  end

  test "the game_started event returns a map structure with the same keys as RoomView.render `room.json`", context do
    {:ok, json_from_event} = GameEvents.game_started(context.room.room_id, context.room)

    json_from_view = PokerExWeb.RoomView.render("room.json", %{room: context.room})

    keys_from_event = Map.keys(json_from_event)
    keys_from_view = Map.keys(json_from_view)

    assert Enum.all?(keys_from_view, fn key -> key in keys_from_event end)
  end

  test "the json rendered from the game_started event has an empty table list and sets the state to `pre_flop`", context do
    {:ok, room_json} = GameEvents.game_started(context.room.room_id, context.room)

    assert room_json.state == :pre_flop
    assert room_json.table == []
  end
end