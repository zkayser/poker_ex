defmodule PokerEx.RoomTest do
  use PokerEx.RoomCase, async: false

  test "the room starts", context do
    assert is_pid(Process.whereis(context[:test_room]))
  end

  test "players can join the room", context do
    player = context[:p1]
    data = Room.join(context[:test_room], player, 200)

    assert {player.name, 0} in data.seating
  end

  test "games begin when a second player joins the room and the start message is sent", context do
    initialize(context)

    assert length(Room.state(context[:test_room]).player_hands) == 2
  end

  test "player 1 should be the small blind and be able to make the first move when a game begins", context do
    initialize(context)
    [p1, _, _, _] = players(context)
    data = Room.raise(context[:test_room], p1, 20)

    assert (data.round[p1.name]) == 20
    assert data.current_small_blind == 0
    assert {p1.name, 0} in data.active
  end

  test "blinds should be posted when the game begins", context do
    initialize(context)

    assert Room.state(context[:test_room]).pot == 15
  end

  describe "SIMPLE HEAD-TO-HEAD GAME: " do
    test "a head-to-head game with only raises and calls should not raise any errors", context do
      init = initialize(context)
      [p1, p2, _, _] = players(context)

      for _ <- 1..3 do
        Room.raise(context[:test_room], p1, 20)
        Room.call(context[:test_room], p2)
      end
      Room.raise(context[:test_room], p1, 20)
      Room.call(context[:test_room], p2)

      refute Room.state(context[:test_room]).chip_roll == init.chip_roll
    end

    test "a player should be able to join in the middle of an ongoing hand", context do
      initialize(context)
      [p1, p2, p3, _] = players(context)

      Room.raise(context[:test_room], p1, 20)
      Room.call(context[:test_room], p2)
      Room.join(context[:test_room], p3, 200)
      data = Room.state(context[:test_room])
      assert {p3.name, 2} in data.seating
      refute {p3.name, 2} in data.active
    end
  end

  describe "FOLDING HEAD-TO-HEAD:" do
    setup [:init]

    test "in head-to-head, the game ends when one player folds", context do
      [p1, p2, _, _] = players(context)
      init = Room.state(context[:test_room])
      Room.raise(context[:test_room], p1, 40)
      Room.fold(context[:test_room], p2)
      finish = Room.state(context[:test_room])

      assert finish.chip_roll[p1.name] > init.chip_roll[p1.name]
      assert finish.chip_roll[p2.name] < init.chip_roll[p2.name]
    end

    test "in head-to-head, the game ends when one player folds in the flop state", context do
      [p1, p2, _, _] = players(context)
      startP1 = context[:init].chip_roll[p1.name]
      startP2 = context[:init].chip_roll[p2.name]
      Room.raise(context[:test_room], p1, 40)
      Room.call(context[:test_room], p2)
      Room.raise(context[:test_room], p1, 40)
      Room.fold(context[:test_room], p2)
      finish = Room.state(context[:test_room])

      assert finish.chip_roll[p1.name] >= startP1 + 30 # Compensating for blinds
      assert finish.chip_roll[p2.name] <= startP2 - 30
    end
  end

  describe "FOLDING WITH MULTIPLE PLAYERS" do
    setup [:initialize_multiplayer]

    test "no errors should arise when a player folds in the pre-flop state", context do
      [p1, p2, p3, p4] = players(context)
      Room.raise(context[:test_room], p1, 20)
      Room.call(context[:test_room], p2)
      data = Room.fold(context[:test_room], p3)
      refute {p3.name, 2} in data.active
      assert {p4.name, 3} in data.active
    end

    test "the game should end when all but one player folds", context do
      [p1, p2, p3, _p4] = players(context)
      simulate_pre_flop_betting(context)
      initial_state = Room.which_state(context[:test_room])
      Room.raise(context[:test_room], p3, 20)
      Room.fold(context[:test_room], p1)
      Room.fold(context[:test_room], p2)
      Room.fold(context[:test_room], p3)

      assert Room.which_state(context[:test_room]) == :pre_flop
      assert initial_state == :flop
    end

    test "the active list should be updated properly when a player folds", context do
      [p1, p2, p3, p4] = players(context)
      simulate_pre_flop_betting(context)
      Room.raise(context[:test_room], p3, 20)
      data = Room.fold(context[:test_room], p4)

      assert hd(data.active) == {p1.name, 0}
      assert data.active == [{p1.name, 0}, {p2.name, 1}, {p3.name, 2}]
    end
  end

  describe "ALL IN, HEAD-TO-HEAD:" do
    setup [:init]

    test "auto-complete should kick in when both players go all_in head-to-head", context do
      [p1, p2, _, _] = players(context)
      startP1 = context[:init].chip_roll[p1.name]
      startP2 = context[:init].chip_roll[p2.name]
      Room.raise(context[:test_room], p1, startP1 + 5)
      Room.call(context[:test_room], p2)

      finish = Room.state(context[:test_room])
      assert Room.which_state(context[:test_room]) == :pre_flop
      assert(finish.chip_roll[p1.name] <= startP1 - 190 || finish.chip_roll[p2.name] <= startP2 - 190,
             "Something weird occurred with the chip count.\n"
             <> "Finished with: #{inspect finish.chip_roll}\n"
             <> "P1 started with: #{inspect startP1}\n"
             <> "P2 started with: #{inspect startP2}"
            )
    end
  end

  describe "ALL IN AUTO-COMPLETE, MULTIPLAYER:" do
    setup [:initialize_multiplayer]

    test "auto-complete kicks in when all players go all_in during pre-flop", context do
      [p1, p2, p3, p4] = players(context)
      Room.raise(context[:test_room], p3, 1200)
      Room.call(context[:test_room], p4)
      Room.call(context[:test_room], p1)
      Room.call(context[:test_room], p2)

      finish = Room.state(context[:test_room]).chip_roll
      assert finish[p1.name] >= 400 || finish[p2.name] >= 400 || finish[p3.name] >= 400 || finish[p4.name] >= 400
      assert Room.which_state(context[:test_room]) == :pre_flop || :idle
    end

    test "auto-complete kicks in when a player folds and the others go all_in during pre-flop", context do
      [p1, p2, p3, p4] = players(context)
      start = Room.state(context[:test_room]).chip_roll
      startP1 = Room.state(context[:test_room]).chip_roll[p1.name]
      Room.raise(context[:test_room], p3, 1200)
      Room.call(context[:test_room], p4)
      Room.fold(context[:test_room], p1)
      Room.call(context[:test_room], p2)

      finish = Room.state(context[:test_room]).chip_roll

      assert startP1 <= finish[p1.name]
      assert(finish[p3.name] >= 400 || finish[p4.name] >= 400 || finish[p2.name] >= 400,
            "\nSomething weird occured with the final chip count.\n"
            <> "The chip roll started with: #{inspect start}\n"
            <> "The finishing chip count was: #{inspect finish}\n"
            )
      assert Room.which_state(context[:test_room]) == :pre_flop
    end

    test "auto-complete kicks in when all players go all_in in later rounds", context do
      [p1, p2, p3, p4] = players(context)
      simulate_pre_flop_betting(context)
      Room.raise(context[:test_room], p3, 1200)
      Room.call(context[:test_room], p4)
      Room.call(context[:test_room], p1)
      Room.call(context[:test_room], p2)

      finish = Room.state(context[:test_room]).chip_roll
      assert finish[p3.name] >= 400 || finish[p4.name] >= 400 || finish[p1.name] >= 400 || finish[p2.name] >= 400
      assert Room.which_state(context[:test_room]) == :pre_flop || :idle || :between_rounds
    end
  end

  describe "HEAD-TO-HEAD CHECK:" do
    setup [:init]

    test "the active list gets updated properly when one player checks", context do
      [p1, p2, _, _] = players(context)
      Room.raise(context[:test_room], p1, 20)
      Room.call(context[:test_room], p2)
      data = Room.check(context[:test_room], p1)

      assert hd(data.active) == {p2.name, 1}
    end
  end

  describe "MULTIPLAYER CHECK:" do
    setup [:initialize_multiplayer]

    test "the active list gets updated properly when a player checks", context do
      [_, _, p3, p4] = players(context)
      simulate_pre_flop_betting(context)
      data = Room.check(context[:test_room], p3)

      assert hd(data.active) == {p4.name, 3}
    end
  end

  defp initialize(context) do
    p1 = context[:p1]
    p2 = context[:p2]
    Room.join(context[:test_room], p1, 200)
    Room.join(context[:test_room], p2, 200)
    Room.start(context[:test_room])
  end

  defp init(context) do
    p1 = context[:p1]
    p2 = context[:p2]
    Room.join(context[:test_room], p1, 200)
    Room.join(context[:test_room], p2, 200)
    Room.start(context[:test_room])
    [init: Room.state(context[:test_room])]
  end

  defp players(context) do
    [context[:p1], context[:p2], context[:p3], context[:p4]]
  end

  defp initialize_multiplayer(context) do
    players = players(context)
    for player <- players, do: Room.join(context[:test_room], player, 200)

    Room.start(context[:test_room])
    [init: Room.state(context[:test_room])]
  end

  defp simulate_pre_flop_betting(context) do
    [p1, p2, p3, p4] = players(context)
    Room.raise(context[:test_room], p3, 20)
    Room.call(context[:test_room], p4)
    Room.call(context[:test_room], p1)
    Room.call(context[:test_room], p2)
  end
end
