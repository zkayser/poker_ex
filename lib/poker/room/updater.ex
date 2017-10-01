defmodule PokerEx.Room.Updater do
  alias PokerEx.Room, as: Room
  alias PokerEx.Deck
  alias PokerEx.Events
  alias PokerEx.Evaluator
  @moduledoc """
    Provides convenience functions for updating specific attributes of
    the Room state individually. This module can be used from other
    modules working with the Room state struct to facilitate updating
    the state in a pipeline.
  """
  @type player :: String.t

  @doc ~S"""
  Updates the seating attribute of a room instance

  ## Examples

      iex> room = %Room{seating: [{"A", 0}, {"B", 1}]}
      iex> Updater.seating(room, "C")
      %Room{seating: [{"A", 0}, {"B", 1}, {"C", 2}]}

  """
  @spec seating(Room.t, player) :: Room.t
  def seating(%Room{seating: seating} = room, player) when is_binary(player) do
    seat_number = length(seating)
    new_seating = [{player, seat_number} | Enum.reverse(seating)] |> Enum.reverse
    %Room{ room | seating: new_seating }
  end

  @doc ~S"""
  Reindexes the indices on the seating attribute of a room instance to
  keep the seat_numbers consistent with each player's position in the
  seating list

  ## Examples

      iex> room = %Room{seating: [{"A", 0}, {"C", 3}]}
      iex> Updater.reindex_seating(room)
      %Room{seating: [{"A", 0}, {"C", 1}]}

  """
  @spec reindex_seating(Room.t) :: Room.t
  def reindex_seating(%Room{seating: seating} = room) when length(seating) >= 1 do
    update =
      for x <- 0..(length(seating) - 1) do
        {name, _} = Enum.at(seating, x)
        {name, x}
      end
    %Room{ room | seating: update }
  end
  def reindex_seating(room), do: room

  @doc ~S"""
  Removes the specified player from the seating list.

  ## Examples

      iex> room = %Room{seating: [{"A", 0}, {"B", 1}, {"C", 2}]}
      iex> Updater.remove_from_seating(room, "B")
      %Room{seating: [{"A", 0}, {"C", 2}]}

      iex> room = %Room{seating: [{"A", 0}]}
      iex> Updater.remove_from_seating(room, "A")
      %Room{seating: []}

  """
  @spec remove_from_seating(Room.t, player) :: Room.t
  def remove_from_seating(%Room{seating: seating} = room, player) do
    update = Enum.reject(seating, fn {name, _} -> player == name end)
    %Room{ room | seating: update }
   end

   @doc ~S"""
   Updates the chip_roll map. If a player is leaving, this function
   simply drops the "#{player}" key from the map; otherwise, it
   updates the value for the "#{player}" key to the given amount.

   ## Examples

      iex> room = %Room{chip_roll: %{"A" => 20, "B" => 30}}
      iex> room = Updater.chip_roll(room, "C", 300)
      iex> room.chip_roll
      %{"A" => 20, "B" => 30, "C" => 300}

      iex> room = %Room{chip_roll: %{"A" => 20, "B" => 30}}
      iex> room = Updater.chip_roll(room, "A", 50)
      iex> room.chip_roll
      %{"A" => 50, "B" => 30}

   """

   @spec chip_roll(Room.t, player, pos_integer | :leaving | {:adding, pos_integer}) :: Room.t
   def chip_roll(%Room{chip_roll: chip_roll} = room, player, :leaving) do
    PokerEx.Player.update_chips(player, chip_roll[player])
    update = Map.drop(chip_roll, [player])
    %Room{ room | chip_roll: update }
   end
   def chip_roll(%Room{chip_roll: chip_roll} = room, player, {:adding, amount}) when amount > 0 do
    {_old, update} = Map.get_and_update(chip_roll, player, fn val -> {val, val + amount} end)
    %Room{ room | chip_roll: update}
   end
   def chip_roll(%Room{chip_roll: chip_roll} = room, player, amount) when amount >= 0 do
    update = Map.put(chip_roll, player, amount)
    %Room{ room | chip_roll: update }
   end

  @doc ~S"""
  Updates the bet required to call or raise. Does nothing if the amount specified is
  less than or equal to the current amount to be called in the to_call attribute

  ## Examples

      iex> room = %Room{to_call: 20}
      iex> Updater.call_amount(room, 40)
      %Room{to_call: 40}

      iex> room = %Room{to_call: 20}
      iex> Updater.call_amount(room, 15)
      %Room{to_call: 20}

      iex> room = %Room{to_call: 20}
      iex> Updater.call_amount(room, 20)
      %Room{to_call: 20}
  """
  @spec call_amount(Room.t, pos_integer) :: Room.t
  def call_amount(%Room{to_call: call_amount} = room, amount) when call_amount <= amount do
    %Room{ room | to_call: amount }
  end
  def call_amount(room, _), do: room

  @doc ~S"""
  Updates the map stored under the round attribute on a room instance.

  ## Examples

      iex> room = %Room{round: %{"A" => 0}}
      iex> Updater.paid_in_round(room, "A", 25)
      %Room{round: %{"A" => 25}}

      iex> room = %Room{round: %{"A" => 25}}
      iex> Updater.paid_in_round(room, "A", 15)
      %Room{round: %{"A" => 40}}

  """
  @spec paid_in_round(Room.t, player, pos_integer) :: Room.t
  def paid_in_round(%Room{round: round} = room, player, amount) do
    update = Map.update(round, player, amount, &(&1 + amount))
    %Room{ room | round: update }
  end

  @doc ~S"""
  Updates the amount stored under the pot attribute on a room instance by
  adding the specified amount.

  ## Examples

      iex> room = %Room{pot: 75}
      iex> Updater.pot(room, 25)
      %Room{pot: 100}

      iex> room = %Room{pot: 75}
      iex> Updater.pot(room, -10)
      %Room{pot: 75}
  """
  @spec pot(Room.t, pos_integer) :: Room.t
  def pot(room, amount) when amount <= 0, do: room
  def pot(%Room{pot: pot} = room, amount), do: %Room{ room | pot: pot + amount}

  @doc ~S"""
  Updates the paid map stored under the paid attribute on a room instance for the
  specified player by adding the specified amount to the current amount.

  ## Examples

      iex> room = %Room{paid: %{"A" => 300}}
      iex> Updater.total_paid(room, "A", 30)
      %Room{paid: %{"A" => 330}}

  """
  @spec total_paid(Room.t, player, pos_integer) :: Room.t
  def total_paid(%Room{paid: paid} = room, player, amount) do
    update = Map.update(paid, player, amount, &(&1 + amount))
    %Room{ room | paid: update }
  end

  @doc ~S"""
  Adds the given player to the front of the list of players who have
  called the current to_call amount.

  ## Examples

      iex> room = %Room{called: ["A", "B"]}
      iex> Updater.called(room, "C")
      %Room{called: ["C", "A", "B"]}

  """
  @spec called(Room.t, player) :: Room.t
  def called(%Room{called: called} = room, player), do: %Room{ room | called: [player | called] }

  @doc ~S"""
  Erases the list of players who have called and adds the specified player
  to the new list. This method is used when a player raises.

  ## Examples

      iex> room = %Room{called: ["A", "B", "C"]}
      iex> Updater.erase_called_with(room, "D")
      %Room{called: ["D"]}

  """
  @spec erase_called_with(Room.t, player) :: Room.t
  def erase_called_with(room, player), do: %Room{ room | called: [player] }

  @doc ~S"""
  Updates the list of players who have gone all in during the
  current game while removing the specified player from the list
  of active players

  ## Examples

      iex> room = %Room{all_in: ["A"], active: [{"C", 2}, {"D", 3}]}
      iex> Updater.all_in(room, "C")
      %Room{all_in: ["C", "A"], active: [{"D", 3}]}

  """
  @spec all_in(Room.t, player) :: Room.t
  def all_in(%Room{all_in: all_in, active: active} = room, player) do
    updated_active = Enum.reject(active, fn {name, _seat_num} -> name == player end)
    updated_all_in = [player | all_in]
    %Room{ room | all_in: updated_all_in, active: updated_active }
  end

  @doc """
  Removes a single player from the active list.
  Note that active/2 removes a player whereas
  active/1 sets the active list at game start.

  ## Examples

      iex> room = %Room{active: [{"A", 0}, {"B", 1}]}
      iex> Updater.active(room, "B")
      %Room{active: [{"A", 0}]}

  """
  @spec active(Room.t, player) :: Room.t
  def active(%Room{active: active} = room, player) do
    update = Enum.reject(active, fn {name, _seat_num} -> name == player end)
    %Room{ room | active: update }
  end

  @doc ~S"""
  Sets the list of players under the seating attribute to active.
  Used when setting up a round.

  ## Examples

      iex> room = %Room{seating: [{"A", 0}, {"B", 1}]}
      iex> Updater.active(room)
      %Room{active: [{"A", 0}, {"B", 1}], seating: [{"A", 0}, {"B", 1}]}

  """
  @spec active(Room.t) :: Room.t
  def active(%Room{seating: seating, active: active} = room) when length(active) == 0 do
    %Room{ room | active: seating }
  end

  @doc ~S"""
  Advances the active player if, and only if, the player passed in to
  the function is the current active player.

  ## Examples
      iex> room = %Room{active: [{"A", 0}, {"B", 1}, {"C", 2}]}
      iex> room = Updater.maybe_advance_active(room, "B")
      iex> room.active
      [{"A", 0}, {"B", 1}, {"C", 2}]

      iex> room = %Room{active: [{"A", 0}, {"B", 1}, {"C", 2}]}
      iex> room = Updater.maybe_advance_active(room, "A")
      iex> room.active
      [{"B", 1}, {"C", 2}, {"A", 0}]
  """
  @spec maybe_advance_active(Room.t, player) :: Room.t
  def maybe_advance_active(%Room{active: [{pl, _}|_tail]} = room, player) when pl == player do
    advance_active(room)
  end
  def maybe_advance_active(room, _player), do: room

  @doc ~S"""
  Rotates the active list to keep the head of the list current as the
  player whose turn it is.

  ## Examples

      iex> room = %Room{active: [{"A", 0}, {"B", 1}, {"C", 2}]}
      iex> Updater.advance_active(room)
      %Room{active: [{"B", 1}, {"C", 2}, {"A", 0}]}

  """
  @spec advance_active(Room.t) :: Room.t
  def advance_active(%Room{active: active, type: :private} = room) when is_list(active) and length(active) > 1 do
    current = hd(active)
    update = Enum.drop(active, 1) ++ [current]
    maybe_send_facebook_notification(hd(update), room.room_id)
    %Room{ room | active: update}
  end
  def advance_active(%Room{active: active} = room) when is_list(active) and length(active) > 1 do
    current = hd(active)
    update = Enum.drop(active, 1) ++ [current]
    %Room{ room | active: update }
  end
  def advance_active(%Room{active: active} = room) when is_list(active) and length(active) == 1, do: room
  def advance_active(room), do: room

  @spec folded(Room.t, player) :: Room.t
  def folded(%Room{folded: folded} = room, player) do
    %Room{ room | folded: [player | folded] }
  end

  @spec reset_folded(Room.t) :: Room.t
  def reset_folded(room) do
    %Room{ room | folded: [] }
  end
  @doc """
  Deals out hands and assigns each hand to active
  players.

  ## Examples

      iex> room = %Room{active: [{"A", 0}, {"B", 1}]}
      iex> room = Updater.player_hands(room)
      iex> length(room.player_hands) == 2
      true

  """
  @spec player_hands(Room.t) :: Room.t
  def player_hands(%Room{deck: deck, active: active, player_hands: player_hands} = room) when length(player_hands) == 0 do
    players = Enum.map(active, fn {player, _} -> player end)
    deck = Deck.shuffle(deck)
    {updated_deck, updated_hands} = deal(players, deck, [], length(players))
    %Room{ room | deck: updated_deck, player_hands: updated_hands }
  end

  @doc """
  Deals a new card to be placed in the list of
  cards showing on the table.

  ## Examples

      iex> room = %Room{table: []}
      iex> room = Updater.table(room)
      iex> length(room.table) == 1
      true

  """
  @spec table(Room.t ) :: Room.t
  def table(%Room{deck: deck, table: table} = room) do
    {new_card, remaining_deck} = Deck.deal(deck, 1)
    %Room{ room | table: table ++ new_card, deck: remaining_deck }
  end

  @doc ~S"""
  Updates the stats attribute on room instances given the player_hands and
  table cards.

  ## Examples

      iex> player_hands = [{"A", [%PokerEx.Card{rank: :two, suit: :hearts}, %PokerEx.Card{rank: :three, suit: :spades}]},
      ...> {"B", [%PokerEx.Card{rank: :four, suit: :clubs}, %PokerEx.Card{rank: :five, suit: :diamonds}]}]
      iex> table = [%PokerEx.Card{rank: :ten, suit: :hearts}, %PokerEx.Card{rank: :jack, suit: :diamonds},
      ...> %PokerEx.Card{rank: :queen, suit: :spades}, %PokerEx.Card{rank: :king, suit: :clubs}, %PokerEx.Card{rank: :ace, suit: :spades}]
      iex> room = %Room{player_hands: player_hands, table: table}
      iex> result = Updater.stats(room)
      iex> result.stats
      [{"A", 414}, {"B", 414}]

  """
  @spec stats(Room.t) :: Room.t
  def stats(%Room{player_hands: player_hands, stats: stats, table: table} = room) when length(stats) == 0 and length(table) == 5 do
    evaluated = Enum.map(player_hands, fn {player, hand} -> {player, Evaluator.evaluate_hand(hand, table)} end)
    stats = Enum.map(evaluated, fn {player, hand} -> {player, hand.score} end)
    %Room{ room | player_hands: evaluated, stats: stats}
  end

  @spec timer(Room.t, pos_integer) :: Room.t
  def timer(%Room{timer: nil, type: :public} = room, time) do
    tref = :erlang.start_timer(time, self(), :auto_fold)
    %Room{ room | timer: tref }
  end
  def timer(%Room{timer: timer, type: :public} = room, time) do
    :erlang.cancel_timer(timer)
    tref = :erlang.start_timer(time, self(), :auto_fold)
    %Room{ room | timer: tref}
  end
  def timer(room, _), do: room

  @spec clear_timer(Room.t) :: Room.t
  def clear_timer(%Room{timer: _timer, type: :public} = room) do
    %Room{ room | timer: nil }
  end
  def clear_timer(room), do: room

  @doc ~S"""
  Allows you to insert an arbitrary score for a given player in the
  list of stats.

  ## Examples

      iex> Updater.insert_stats(%Room{}, "B", 100)
      %Room{stats: [{"B", 100}]}

  """
  @spec insert_stats(Room.t, player, pos_integer) :: Room.t
  def insert_stats(%Room{stats: stats} = room, player, number) do
    %Room{ room | stats: stats ++ [{player, number}] }
  end

  @doc ~S"""
  Allows you to arbitrarily insert a winner.

  ## Examples

      iex> Updater.insert_winner(%Room{}, "A")
      %Room{winner: "A"}

  """
  @spec insert_winner(Room.t, player) :: Room.t
  def insert_winner(room, player), do: %Room{ room | winner: player }

  @doc ~S"""
  Evaluates player hands and determines the winner, then assigns the winner
  and winning_hand to their respective attributes in the room instance.

  ## Examples

      iex> player_hands = [{"A", [%PokerEx.Card{rank: :two, suit: :hearts}, %PokerEx.Card{rank: :three, suit: :hearts}]},
      ...> {"B", [%PokerEx.Card{rank: :four, suit: :clubs}, %PokerEx.Card{rank: :five, suit: :diamonds}]},
      ...> {"C", [%PokerEx.Card{rank: :six, suit: :diamonds}, %PokerEx.Card{rank: :seven, suit: :clubs}]}]
      iex> table = [%PokerEx.Card{rank: :ten, suit: :hearts}, %PokerEx.Card{rank: :jack, suit: :diamonds},
      ...> %PokerEx.Card{rank: :queen, suit: :hearts}, %PokerEx.Card{rank: :king, suit: :hearts}, %PokerEx.Card{rank: :ace, suit: :spades}]
      iex> active = [{"A", 0}]
      iex> all_in = ["B"]
      iex> room = %Room{player_hands: player_hands, table: table, active: active, all_in: all_in}
      iex> room = Updater.stats(room)
      iex> room = Updater.winner(room)
      iex> {room.winner, room.winning_hand.type_string}
      {"A", "a Flush, King High"}

  """
  @spec winner(Room.t) :: Room.t
  def winner(%Room{active: active, all_in: all_in, stats: stats, player_hands: player_hands} = room) do
    players = for {player, _seat} <- active, do: player
    players = players ++ all_in
    eligible_stats = Enum.filter(stats, fn {pl, _score} -> pl in players end) |> Enum.sort(fn {_, score1}, {_, score2} -> score1 > score2 end)
    {winner, _} = List.first(eligible_stats)
    {^winner, winning_hand} = Enum.find(player_hands, fn {pl, _hand} -> pl == winner end)
    %Room{ room | stats: eligible_stats, winner: winner, winning_hand: winning_hand}
  end


  #############################
  # Round Transition updaters #
  #############################

  @doc ~S"""
  Sets the skip_advance? flag on the room to true to skip
  sending the advance event when a player calls or checks
  to move on to the next round.

  ## Examples

      iex> room = %Room{}
      iex> Updater.no_advance_event(room)
      iex> room.skip_advance?
      false

  """

  @spec no_advance_event(Room.t) :: Room.t
  def no_advance_event(room) do
    %Room{ room | skip_advance?: true}
  end

  @doc ~S"""
  Sets the skip_advance? flag back to false.
  """
  @spec reset_advance_event_flag(Room.t) :: Room.t
  def reset_advance_event_flag(room), do: %Room{ room | skip_advance?: false }

  @doc ~S"""
  Resets the active list and sets the small_blind and big_blind as the last two
  players in the list, respectively.

  ## Examples

      iex> room = %Room{active: [{"A", 0}, {"B", 1}, {"C", 2}], current_big_blind: 1, current_small_blind: 0}
      iex> room = Updater.reset_active(room)
      iex> room.active
      [{"C", 2}, {"A", 0}, {"B", 1}]

  """
  @spec reset_active(Room.t) :: Room.t
  def reset_active(%Room{active: active} = room) when length(active) <= 1, do: room
  def reset_active(%Room{active: active, current_big_blind: bb, current_small_blind: sb} = room) do
    big = Enum.filter(active, fn {_, seat} -> seat == bb end)
    small = Enum.filter(active, fn {_, seat} -> seat == sb end)
    rest = Enum.filter(active, fn {_, seat} -> seat != bb && seat != sb end)
    update = rest ++ small ++ big
    %Room{ room | active: update }
  end

  @doc ~S"""
  Resets the round map on a room instance to an empty map.

  ## Examples

      iex> room = %Room{round: %{"A" => 100, "B" => 50}}
      iex> room = Updater.reset_paid_in_round(room)
      iex> room.round
      %{}

  """
  @spec reset_paid_in_round(Room.t) :: Room.t
  def reset_paid_in_round(room), do: %Room{ room | round: %{} }

  @doc ~S"""
  Resets the to_call amount to zero.

  ## Examples

      iex> room = %Room{to_call: 500}
      iex> room = Updater.reset_call_amount(room)
      iex> room.to_call
      0

  """
  @spec reset_call_amount(Room.t) :: Room.t
  def reset_call_amount(room), do: %Room{ room | to_call: 0 }

  @doc ~S"""
  Resets the called list to an empty list

  ## Examples

      iex> room = %Room{called: ["A", "B", "C"]}
      iex> room = Updater.reset_called(room)
      iex> room.called
      []

  """
  @spec reset_called(Room.t) :: Room.t
  def reset_called(room), do: %Room{ room | called: [] }

  ############################
  # Game transition updaters #
  ############################

  @doc ~S"""
  Updates the blinds between rounds and before the first game played at a
  table. If both the current_big_blind and current_small_blind data attributes
  are nil, they are set to 1 and 0 by default, respectively. If the big blind
  is currently equal to the length of the seating list minus 1, the big blind
  position gets reset to 0. If the big blind is less than the small blind (in
  terms of seating position), the small blind gets reset to 0 while the big_blind
  moves up to 1.

  ## Examples

      iex> room = %Room{current_big_blind: nil, current_small_blind: nil}
      iex> room = Updater.blinds(room)
      iex> {room.current_small_blind, room.current_big_blind}
      {0, 1}

      iex> room = %Room{current_big_blind: 1, current_small_blind: 0, seating: [{"A", 0}, {"B", 1}, {"C", 2}, {"D", 3}]}
      iex> room = Updater.blinds(room)
      iex> {room.current_small_blind, room.current_big_blind}
      {1, 2}

      iex> room = %Room{current_big_blind: 3, current_small_blind: 2, seating: [{"A", 0}, {"B", 1}, {"C", 2}, {"D", 3}]}
      iex> room = Updater.blinds(room)
      iex> {room.current_small_blind, room.current_big_blind}
      {3, 0}

      iex> room = %Room{current_big_blind: 0, current_small_blind: 3, seating: [{"A", 0}, {"B", 1}, {"C", 2}, {"D", 3}]}
      iex> room = Updater.blinds(room)
      iex> {room.current_small_blind, room.current_big_blind}
      {0, 1}

      iex> room = %Room{current_big_blind: 2, current_small_blind: 1, seating: [{"A", 0}, {"B", 1}, {"C", 2}, {"D", 3}]}
      iex> room = Updater.blinds(room)
      iex> {room.current_small_blind, room.current_big_blind}
      {2, 3}

  """
  @spec blinds(Room.t) :: Room.t
  def blinds(%Room{current_big_blind: big_blind, current_small_blind: small_blind} = room)
  when is_nil(big_blind) and is_nil(small_blind) do
    %Room{ room | current_big_blind: 1, current_small_blind: 0 }
  end
  def blinds(%Room{current_big_blind: big_blind, current_small_blind: small_blind} = room) when big_blind < small_blind do
    %Room{ room | current_big_blind: big_blind + 1, current_small_blind: 0 }
  end
  def blinds(%Room{current_big_blind: big_blind, seating: seating} = room)
  when length(seating) < big_blind + 1 do
    %Room{ room | current_big_blind: big_blind + 1, current_small_blind: big_blind }
  end
  def blinds(%Room{current_big_blind: big_blind, seating: seating} = room)
  when length(seating) == big_blind + 1 do
    %Room{ room | current_big_blind: 0, current_small_blind: big_blind }
  end
  def blinds(%Room{current_big_blind: big_blind, current_small_blind: small_blind} = room) do
    %Room{ room | current_big_blind: big_blind + 1, current_small_blind: small_blind + 1 }
  end

  @doc ~S"""
  Sets the list of active players based on the seating list and the
  current big blind position

  ## Examples

      iex> room = %Room{seating: [{"A", 0}, {"B", 1}, {"C", 2}, {"D", 3}], current_big_blind: 2}
      iex> room = Updater.set_active(room)
      iex> room.active
      [{"D", 3}, {"A", 0}, {"B", 1}, {"C", 2}]

  """
  @spec set_active(Room.t) :: Room.t
  def set_active(%Room{seating: seating, current_big_blind: big_blind} = room) do
    {back, front} = Enum.split_while(seating, fn {_player, seat} -> seat <= big_blind end)
    %Room{ room | active: front ++ back }
  end

  @doc ~S"""
  Removes players whose chip counts have fallen to zero and reindexes
  the list.

  ## Examples
      iex> room = %Room{chip_roll: %{"Donatello" => 0, "Michelangelo" => 2000}}
      iex> room = %Room{room | seating: [{"Donatello", 0}, {"Michelangelo", 1}]}
      iex> room = Updater.remove_players_with_no_chips(room)
      iex> room.seating
      [{"Michelangelo", 0}]

  """
  @spec remove_players_with_no_chips(Room.t) :: Room.t
  def remove_players_with_no_chips(%Room{seating: seating, chip_roll: chip_roll} = room) do
    updated_seating =
      Enum.reject(seating,
        fn {player, _} ->
          if chip_roll[player] == 0, do: Events.player_left(room.room_id, player)
          chip_roll[player] == 0
        end)

      remove_keys =
        Enum.filter(seating, fn {player, _} -> chip_roll[player] == 0 end)
        |> Enum.map(fn {player, _} -> player end)

      updated_chip_roll = Map.drop(chip_roll, remove_keys)

    update =
      for x <- 0..(length(updated_seating) - 1) do
        {name, _} = Enum.at(updated_seating, x)
        {name, x}
      end
    %Room{ room | seating: update, chip_roll: updated_chip_roll }
  end

  @doc ~S"""
  Resets the :paid attribute on a room instance to an
  empty map.

  ## Examples

      iex> room = %Room{paid: %{"A" => 345, "B" => 700}}
      iex> room = Updater.reset_total_paid(room)
      iex> room.paid
      %{}

  """
  @spec reset_total_paid(Room.t) :: Room.t
  def reset_total_paid(room), do: %Room{ room | paid: %{} }

  @doc ~S"""
  Resets the player_hands attribute on a Room instance to an
  empty list.

  ## Examples

      iex> room = %Room{player_hands: {"A", [%PokerEx.Card{rank: :two, suit: :spades}, %PokerEx.Card{rank: :three, suit: :spades}]}}
      iex> room = Updater.reset_player_hands(room)
      iex> room.player_hands
      []

  """
  @spec reset_player_hands(Room.t) :: Room.t
  def reset_player_hands(room), do: %Room{ room | player_hands: [] }

  @doc ~S"""
  Resets the table attribute on a room instance to an empty list.

  ## Examples

      iex> room = %Room{table: [%PokerEx.Card{rank: :two, suit: :spades}, %PokerEx.Card{rank: :three, suit: :spades},
      ...> %PokerEx.Card{rank: :four, suit: :spades}]}
      iex> room = Updater.reset_table(room)
      iex> room.table
      []

  """
  @spec reset_table(Room.t) :: Room.t
  def reset_table(room), do: %Room{ room | table: [] }

  @doc ~S"""
  Resets the rewards list to an empty list.

  ## Examples

      iex> rewards = [{"A", 20}, {"B", 75}]
      iex> room = %Room{rewards: rewards}
      iex> room = Updater.reset_rewards(room)
      iex> [] == room.rewards
      true
  """
  @spec reset_rewards(Room.t) :: Room.t
  def reset_rewards(room), do: %Room{ room | rewards: [] }

  @doc ~S"""
  Resets the deck attribute to store a fresh, shuffled deck.

  ## Examples

      iex> deck = PokerEx.Deck.new |> PokerEx.Deck.shuffle
      iex> room = %Room{deck: deck}
      iex> room = Updater.reset_deck(room)
      iex> deck == room.deck
      false

  """
  @spec reset_deck(Room.t) :: Room.t
  def reset_deck(room), do: %Room{ room | deck: Deck.new |> Deck.shuffle }

  @doc ~S"""
  Resets the stats list on a room instance to an empty list.

  ## Examples

      iex> stats = [{"A", 400}, {"B", 600}]
      iex> room = %Room{stats: stats}
      iex> room = Updater.reset_stats(room)
      iex> room.stats
      []

  """
  @spec reset_stats(Room.t) :: Room.t
  def reset_stats(room), do: %Room{ room | stats: [] }

  @doc ~S"""
  Resets the winner attribute on a room instance to nil

  ## Examples

      iex> room = %Room{winner: "A"}
      iex> room = Updater.reset_winner(room)
      iex> room.winner
      nil

  """
  @spec reset_winner(Room.t) :: Room.t
  def reset_winner(room), do: %Room{ room | winner: nil }

  @doc ~S"""
  Resets the winning_hand attribute on a room instance to nil.

  ## Examples

      iex> room = %Room{winning_hand: %PokerEx.Hand{score: 600, best_hand: []}}
      iex> room = Updater.reset_winning_hand(room)
      iex> room.winning_hand
      nil

  """
  @spec reset_winning_hand(Room.t) :: Room.t
  def reset_winning_hand(room), do: %Room{ room | winning_hand: nil }

  @doc ~S"""
  Resets the pot attribute back to zero on a room instance.

  ## Examples

      iex> room = %Room{pot: 500}
      iex> room = Updater.reset_pot(room)
      iex> room.pot
      0

  """
  @spec reset_pot(Room.t) :: Room.t
  def reset_pot(room), do: %Room{ room | pot: 0 }

  @doc ~S"""
  Removes the player from the list of active players

  ## Examples

      iex> room = %Room{active: [{"A", 0}, {"B", 1}, {"C", 2}]}
      iex> room = Updater.remove_from_active(room, "A")
      iex> room.active
      [{"B", 1}, {"C", 2}]
  """
  @spec remove_from_active(Room.t, player) :: Room.t
  def remove_from_active(%Room{active: active} = room, player) do
    update = Enum.reject(active, fn {pl, _} -> pl == player end)
    %Room{ room | active: update }
  end

  @doc ~S"""
  Resets the list of all_in players to an empty list.

  ## Examples

      iex> room = %Room{all_in: ["A", "B", "C", "D"]}
      iex> room = Updater.reset_all_in(room)
      iex> room.all_in
      []

  """
  @spec reset_all_in(Room.t) :: Room.t
  def reset_all_in(room), do: %Room{ room | all_in: [] }

  @spec reset_round(Room.t) :: Room.t
  def reset_round(room), do: %Room{ room | round: %{} }

  @spec clear_active(Room.t) :: Room.t
  def clear_active(room), do: %Room{ room | active: [] }

  @spec reset_table_state(Room.t) :: Room.t
  def reset_table_state(room) do
    room
    |> reset_all_in
    |> reset_pot
    |> reset_winning_hand
    |> reset_winner
    |> reset_stats
    |> reset_deck
    |> reset_player_hands
    |> reset_total_paid
    |> reset_folded
    |> reset_table
  end

  @spec clear_room(Room.t) :: Room.t
  def clear_room(room) do
    room
    |> reset_table_state
    |> reset_round
    |> clear_active
  end


  #####################
  # Utility Functions #
  #####################

  defp deal(players, deck, updated, number) when length(updated) < number do
		player = List.first(players)
		{hand, remaining} = Deck.deal(deck, 2)
		deal(players -- [player], remaining, updated ++ [{player, hand}], number)
	end
	defp deal(_, deck, updated, _), do: {deck, updated}

	defp maybe_send_facebook_notification({user_name, _}, room_id) do
	  user = PokerEx.Repo.get_by(PokerEx.Player, name: user_name)
	  if user, do: send_notification(user, room_id)
	end

	def send_notification(user, room_id) do
	  case user.facebook_id do
	    nil -> :ok
	    id when is_binary(id) ->
	      Task.start(fn ->
	        PokerEx.Services.Facebook.notify_user(
	          %{user_id: id,
	            template: template(user.name),
	            return_url: form_url(room_id)})
	      end)
	     _ -> :ok
	  end
	end

	defp template(user_name) do
	  "#{user_name}, it looks like its your turn to make a move in PokerEx!"
	end

	defp form_url(room_id) do
	  "private/rooms/#{room_id}"
	end
end
