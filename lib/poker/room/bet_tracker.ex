defmodule PokerEx.Room.BetTracker do
  alias PokerEx.Room, as: Room
  alias PokerEx.Room.Updater
  alias PokerEx.Player
  
  @moduledoc """
    Provides convenience functions for manipulating Room state data
    pertaining to bets and actions taken by players.
  """
  @type player :: String.t
  @type blind :: :big_blind | :small_blind
  
  @doc ~S"""
  Posts the big and small blinds. Puts either player all_in
  if the player has insufficient chips.
  
  ## Examples
  
      iex> active = [{"A", 0}, {"B", 1}]
      iex> room = %Room{current_big_blind: 1, current_small_blind: 0, active: active}
      iex> PokerEx.AppState.put(PokerEx.Player.new("A"))
      iex> PokerEx.AppState.put(PokerEx.Player.new("B"))
      iex> room = BetTracker.post_blind(room, 10, :big_blind)
      iex> {room.to_call, room.round, room.pot, room.paid}
      {10, %{"B" => 10}, 10, %{"B" => 10}}
      
  """
  @spec post_blind(Room.t, pos_integer, blind) :: Room.t
  def post_blind(%Room{current_big_blind: bb, current_small_blind: sb, active: active} = room, amount, blind) do
    {bb, sb} = 
      if bb > length(active) || sb > length(active) do
        {length(active) - 1, length(active) - 2}
      else
        {bb, sb}
      end
  
    {player, _} = 
      case blind do
        :big_blind -> 
          Enum.find(active, fn {_name, seat} -> seat == bb end)
        :small_blind ->
          Enum.find(active, fn {_name, seat} -> seat == sb end)
      end
    
    case Player.bet(player, amount, room.room_id) do
      %Player{name: _, chips: _} ->
        room
        |> Updater.call_amount(amount)
        |> Updater.paid_in_round(player, amount)
        |> Updater.pot(amount)
        |> Updater.total_paid(player, amount)
      {:insufficient_chips, total} ->
        room
        |> Updater.call_amount(amount)
        |> Updater.paid_in_round(player, total)
        |> Updater.pot(total)
        |> Updater.total_paid(player, total)
        |> Updater.all_in(player)
        |> Updater.active(player)
    end
  end
  
  
  @doc ~S"""
  Updates the room state appropriately when a player raises.
  
  ## Examples
  
      iex> room = %Room{active: [{"A", 0}, {"B", 1}], to_call: 20, round: %{"B" => 20, "A" => 5},
      ...> paid: %{"B" => 20, "A" => 5}, called: ["B"], pot: 25}
      iex> PokerEx.AppState.put(PokerEx.Player.new("A"))
      iex> PokerEx.AppState.put(PokerEx.Player.new("B"))
      iex> room = BetTracker.raise(room, "A", 40)
      iex> {room.to_call, room.called, room.round, room.pot, room.paid}
      {40, ["A"], %{"A" => 40, "B" => 20}, 60, %{"A" => 40, "B" => 20}}
      
  """
  @spec raise(Room.t, player, pos_integer) :: Room.t
  def raise(%Room{to_call: call_amount, round: paid_in_round} = room, player, amount) 
  when amount > call_amount do
    paid_in_round = paid_in_round[player] || 0
    bet_amount = amount - paid_in_round
    
    case Player.bet(player, bet_amount, room.room_id) do
      %Player{name: _, chips: _} ->
        room 
        |> Updater.call_amount(amount)
        |> Updater.paid_in_round(player, bet_amount)
        |> Updater.pot(bet_amount)
        |> Updater.total_paid(player, bet_amount)
        |> Updater.erase_called_with(player)
        |> Updater.advance_active
      {:insufficient_chips, total} ->
        room
        |> Updater.call_amount(total)
        |> Updater.paid_in_round(player, total)
        |> Updater.pot(total)
        |> Updater.total_paid(player, total)
        |> Updater.all_in(player)
        #|> Updater.active(player)
        #|> Updater.advance_active
    end
  end
  
  @doc ~S"""
  Updates the room state appropriately when a player checks.
  
  ## Examples
  
      iex> room = %Room{to_call: 30, round: %{"A" => 20, "B" => 30}, paid: %{"A" => 20, "B" => 30},
      ...> active: [{"A", 0}, {"B", 1}], pot: 50, called: ["B"]}
      iex> PokerEx.AppState.put(PokerEx.Player.new("A"))
      iex> PokerEx.AppState.put(PokerEx.Player.new("B"))
      iex> room = BetTracker.call(room, "A")
      iex> {room.to_call, room.called, room.round, room.paid, room.pot}
      {30, ["A", "B"], %{"A" => 30, "B" => 30}, %{"A" => 30, "B" => 30}, 60}
      
  """
  @spec call(Room.t, player) :: Room.t
  def call(%Room{to_call: call_amount, round: paid_in_round} = room, player) do
    paid_in_round = paid_in_round[player] || 0
    bet_amount = call_amount - paid_in_round
    
    case Player.bet(player, bet_amount, room.room_id) do
      %Player{name: _, chips: _} ->
        room
        |> Updater.paid_in_round(player, bet_amount)
        |> Updater.pot(bet_amount)
        |> Updater.total_paid(player, bet_amount)
        |> Updater.called(player)
        |> Updater.advance_active
      {:insufficient_chips, total} ->
        room
        |> Updater.paid_in_round(player, total)
        |> Updater.pot(total)
        |> Updater.total_paid(player, total)
        |> Updater.all_in(player)
        # Updater.active(player) <- deleted from pipeline
    end
  end
  
  @doc ~S"""
  Updates the room state appropriately when a player checks.
  
  ## Examples
  
      iex> room = %Room{active: [{"A", 0}, {"B", 1}], paid: %{"A" => 30, "B" => 30}, to_call: 30, called: ["B"]}
      iex> room = BetTracker.check(room, "A")
      iex> room.called
      ["A", "B"]
      
  """
  @spec check(Room.t, player) :: Room.t
  def check(room, player) do
    room
    |> Updater.called(player)
    |> Updater.advance_active
  end
  
  @doc ~S"""
  Updates the room state appropriatel when a player folds.
  
  ## Examples
  
      iex> room = %Room{active: [{"A", 0}, {"B", 1}, {"C", 2}]}
      iex> room = BetTracker.fold(room, "B")
      iex> room.active
      [{"C", 2}, {"A", 0}]
      
  """
  @spec fold(Room.t, player) :: Room.t
  def fold(%Room{active: active} = room, player) when length(active) > 1 do
    room
    |> Updater.advance_active 
    |> Updater.active(player)
    |> Updater.folded(player)
  end
end