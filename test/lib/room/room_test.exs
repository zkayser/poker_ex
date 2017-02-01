defmodule PokerEx.RoomTest do
  use ExUnit.Case
  alias PokerEx.Room
  alias PokerEx.Player
  alias PokerEx.Repo
  
  setup do
    room = 
      case Room.start_test(self()) do
        {:ok, pid} -> pid
        {:error, _} -> Process.whereis(:test)
      end
    
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    
    [p1, p2, p3, p4] = 
      for x <- 1..4 do
        changeset = Player.registration_changeset(%Player{}, 
          %{
            "name" => "Player #{x}", 
            "email" => "email#{x}@mail.com",
            "password" => "password",
            "first_name" => "#{x}",
            "last_name" => "#{x}"
          })
        Repo.insert(changeset)
      end
    |> Enum.map(fn {:ok, player} -> player end)
    
    # on_exit fn -> Process.exit(room, :kill) end
    
    [room: room, p1: p1, p2: p2, p3: p3, p4: p4]
  end
  
  test "the room starts", context do
    assert is_pid(context[:room])
  end
  
  test "players can join the room", context do
    player = context[:p1]
    Room.t_join(player)
    
    assert {player.name, 0} in Room.t_state.seating
  end
  
  test "games begin when a second player joins the room", context do
    initialize(context)
    
    assert length(Room.t_state.player_hands) == 2
  end
  
  test "player 1 should be the small blind and be able to make the first move when a game begins", context do
    initialize(context)
    [p1, _, _, _] = players(context)
    Room.t_raise(p1, 20)
    
    assert (Room.t_state.round[p1.name]) == 20
    assert Room.t_state.current_small_blind == 0
    assert {p1.name, 0} in Room.t_state.active
  end
  
  test "blinds should be posted when the game begins", context do
    initialize(context)
    
    assert Room.t_state.pot == 15
  end
  
  describe "SIMPLE HEAD-TO-HEAD GAME: " do
    test "a head-to-head game with only raises and calls should not raise any errors", context do
      initialize(context)
      [p1, p2, _, _] = players(context)
      
      for _ <- 1..3 do
        Room.t_raise(p1, 20)
        Room.t_call(p2)
      end
      Room.t_raise(p1, 20)
      Room.t_call(p2)
      
      assert_receive :rewarding_winner
    end
    
    test "a player should be able to join in the middle of an ongoing hand", context do
      initialize(context)
      [p1, p2, p3, _] = players(context)
      
      Room.t_raise(p1, 20)
      Room.t_call(p2)
      Room.t_join(p3)
      assert {p3.name, 2} in Room.t_state.seating
      refute {p3.name, 2} in Room.t_state.active
    end
  end
  
  describe "FOLDING HEAD-TO-HEAD:" do
    setup [:initialize]
  
    test "in head-to-head, the game ends when one player folds", context do
      [p1, p2, _, _] = players(context)
      Room.t_raise(p1, 40)
      Room.t_fold(p2)
      
      assert_receive :handling_fold_and_marking_winner
    end
    
    test "in head-to-head, the game ends when one player folds in the flop state", context do
      [p1, p2, _, _] = players(context)
      p1_start = Repo.get_by(Player, name: p1.name).chips
      p2_start = Repo.get_by(Player, name: p2.name).chips
      Room.t_raise(p1, 40)
      Room.t_call(p2)
      Room.t_raise(p1, 40)
      Room.t_fold(p2)
      assert_receive :handling_fold_and_marking_winner
    end
  end
  
  describe "FOLDING WITH MULTIPLE PLAYERS" do
    setup [:initialize_multiplayer]
    
    test "no errors should arise when a player folds in the pre-flop state", context do
      [p1, p2, p3, p4] = players(context)
      Room.t_raise(p1, 20)
      Room.t_call(p2)
      Room.t_fold(p3)
      refute {p3.name, 2} in Room.t_state.active
      assert {p4.name, 3} in Room.t_state.active
    end
    
    test "the game should end when all but one player folds", context do
      [p1, p2, p3, p4] = players(context)
      p4_start = Repo.get_by(Player, name: p4.name).chips
      simulate_pre_flop_betting(context)
      Room.t_raise(p4, 20)
      Room.t_fold(p1)
      Room.t_fold(p2)
      Room.t_fold(p3)
      
      assert_receive :handling_fold_and_marking_winner
    end
    
    test "the active list should be updated properly when a player folds", context do
      [p1, p2, p3, p4] = players(context)
      simulate_pre_flop_betting(context)
      Room.t_raise(p4, 20)
      Room.t_fold(p1)
      
      assert hd(Room.t_state.active) == {p2.name, 1}
      assert Room.t_state.active == [{p2.name, 1}, {p3.name, 2}, {p4.name, 3}]
    end
  end
  
  describe "ALL IN, HEAD-TO-HEAD:" do
    setup [:initialize]
    
    test "auto-complete should kick in when both players go all_in head-to-head", context do
      [p1, p2, _, _] = players(context)
      Room.t_raise(p1, 1000)
      Room.t_call(p2)
      
      assert_receive :handle_all_in_marking_winner
    end
  end
  
  describe "ALL IN AUTO-COMPLETE, MULTIPLAYER:" do
    setup [:initialize_multiplayer]
    
    test "auto-complete kicks in when all players go all_in during pre-flop", context do
      players = [p1, p2, p3, p4] = players(context)
      Room.t_raise(p4, 1200)
      Room.t_call(p1)
      Room.t_call(p2)
      Room.t_call(p3)
      
      assert_receive :handling_fold_and_marking_winner
    end
    
    test "auto-complete kicks in when a player folds and the others go all_in during pre-flop", context do
      players = [p1, p2, p3, p4] = players(context)
      Room.t_raise(p4, 1200)
      Room.t_call(p1)
      Room.t_fold(p2)
      Room.t_call(p3)
      
      assert_receive :handling_fold_and_marking_winner
    end
    
    test "auto-complete kicks in when all players go all_in in later rounds", context do
      players = [p1, p2, p3, p4] = players(context)
      simulate_pre_flop_betting(context)
      Room.t_raise(p4, 1200)
      Room.t_call(p1)
      Room.t_call(p2)
      Room.t_call(p3)
      
      assert_receive :handling_fold_and_marking_winner
    end
  end
  
  describe "HEAD-TO-HEAD CHECK:" do
    setup [:initialize]
    
    test "the active list gets updated properly when one player checks", context do
      [p1, p2, _, _] = players(context)
      Room.t_raise(p1, 20)
      Room.t_call(p2)
      Room.t_check(p1)
      
      assert hd(Room.t_state.active) == {p2.name, 1}
    end
  end
  
  describe "MULTIPLAYER CHECK:" do
    setup [:initialize_multiplayer]
    
    test "the active list gets updated properly when a player checks", context do
      [p1, _, _, p4] = players(context)
      simulate_pre_flop_betting(context)
      Room.t_check(p4)
      
      assert hd(Room.t_state.active) == {p1.name, 0}
    end
  end
  
  defp initialize(context) do
    p1 = context[:p1]
    p2 = context[:p2]
    Room.t_join(p1)
    Room.t_join(p2)
  end
  
  defp players(context) do
    [context[:p1], context[:p2], context[:p3], context[:p4]]
  end
  
  defp initialize_multiplayer(context) do
    players = [p1, p2, _p3, _p4] = players(context)
    for player <- players, do: Room.t_join(player)
    
    Room.t_raise(p1, 20)
    Room.t_fold(p2)
  end
  
  defp simulate_pre_flop_betting(context) do
    [p1, p2, p3, p4] = players(context)
    Room.t_raise(p4, 20)
    Room.t_call(p1)
    Room.t_call(p2)
    Room.t_call(p3)
  end
end