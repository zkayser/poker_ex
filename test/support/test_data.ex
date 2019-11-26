defmodule PokerEx.TestData do
  alias PokerEx.GameEngine.Impl, as: Engine
  alias PokerEx.GameEngine.{ChipManager, PlayerTracker, Seating, CardManager, RoleManager}
  @join_amount 200

  @doc """
  Takes a context object with a map that contains
  six players (constitutes a full room).
  The context is assumed to contain a map that
  conforms to the following structure:
  %{p1: p1, p2: p2, p3: p3, p4: p4, p5: p5, p6: p6}
  where each value is a PokerEx.Player struct.
  Each player joins the game with 200 chips
  """
  def join_all(context) do
    [context.p1, context.p2, context.p3, context.p4, context.p5, context.p6]
    |> Enum.reduce(Engine.new(), &join/2)
  end

  defp join(player, {:ok, engine}), do: Engine.join(engine, player, @join_amount)
  defp join(player, engine), do: Engine.join(engine, player, @join_amount)

  def insert_active_players(%{p1: p1, p2: p2, p3: p3, p4: p4, p5: p5, p6: p6}) do
    names = for player <- [p1, p2, p3, p4, p5, p6], do: player
    %PlayerTracker{active: names}
  end

  def seat_players(%{p1: p1, p2: p2, p3: p3, p4: p4, p5: p5, p6: p6}) do
    seating =
      for {player, seat} <- [
            {p1, 0},
            {p2, 1},
            {p3, 2},
            {p4, 3},
            {p5, 4},
            {p6, 5}
          ] do
        {player, seat}
      end

    %Seating{arrangement: seating}
  end

  def seat_two(%{p1: p1, p2: p2}) do
    %Seating{arrangement: for({player, seat} <- [{p1, 0}, {p2, 1}], do: {player.name, seat})}
  end

  def call_for_players(tracker, players) when is_list(players) do
    names = for player <- players, do: player.name
    %PlayerTracker{tracker | called: names}
  end

  def call_for_all(tracker, %{p1: p1, p2: p2, p3: p3, p4: p4, p5: p5, p6: p6}) do
    call_for_players(tracker, [p1, p2, p3, p4, p5, p6])
  end

  def put_all_players_all_in(%{p1: p1, p2: p2, p3: p3, p4: p4, p5: p5, p6: p6}) do
    names = for player <- [p1, p2, p3, p4, p5, p6], do: player.name
    %PlayerTracker{all_in: names}
  end

  def all_in_for_all_but_first(tracker, %{p1: _, p2: p2, p3: p3, p4: p4, p5: p5, p6: p6}) do
    names = for player <- [p2, p3, p4, p5, p6], do: player.name
    %PlayerTracker{tracker | all_in: names}
  end

  def fold_for_all_but_first(tracker, %{p1: _, p2: p2, p3: p3, p4: p4, p5: p5, p6: p6}) do
    names = for player <- [p2, p3, p4, p5, p6], do: player.name
    %PlayerTracker{tracker | folded: names}
  end

  def add_200_chips_for_all(%{p1: p1, p2: p2, p3: p3, p4: p4, p5: p5, p6: p6}) do
    chip_roll =
      for player <- [p1, p2, p3, p4, p5, p6], into: %{} do
        {player.name, @join_amount}
      end

    %ChipManager{chip_roll: chip_roll}
  end

  def pay_200_chips_for_all(%{p1: p1, p2: p2, p3: p3, p4: p4, p5: p5, p6: p6}) do
    paid =
      for player <- [p1, p2, p3, p4, p5, p6], into: %{} do
        {player.name, 200}
      end

    %ChipManager{paid: paid}
  end

  def setup_cards_and_deck(context) do
    ## The setup work in the following lines ensures that a deck has been
    ## instantiated. It is not otherwise necessary. Trying to takes cards
    ## from an uninstantiated deck (an empty list value) throws a Runtime
    ## Exception inside of the Deck module (see PokerEx.Deck.deal/2)
    engine = Map.put(Engine.new(), :seating, seat_players(context))

    Map.update(engine, :cards, %{}, fn _ ->
      {:ok, card_manager} = CardManager.deal(engine, :pre_flop)
      card_manager
    end)
  end

  @doc """
  Sets up the role manager for a multi-player game
  """
  def setup_roles(engine) do
    Map.put(engine, :roles, %RoleManager{dealer: 0, small_blind: 1, big_blind: 2})
  end

  @doc """
  Sets up the chips in accordance with starting a multi-player
  game. The big blind (context.p3) will pay 10, the small_blind
  will pay 5 (context.p2 will be the small blind), and the `round`
  and `paid` attributes of the ChipManager will be set. The `to_call`
  amounts and `pot` amounts will be set to 10 and 15, respectively
  """
  def setup_chips(engine, context) do
    Map.update(engine, :chips, %{}, fn chips ->
      Map.put(chips, :to_call, 10)
      |> Map.put(:pot, 15)
      |> Map.put(:paid, %{context.p2.name => 5, context.p3.name => 10})
      |> Map.put(:round, %{context.p2.name => 5, context.p3.name => 10})
    end)
  end

  @doc """
  Rotates active list to first player's turn. Because of
  the roles, context.p4 should be the first player to go.
  """
  def cycle_to_first_move(engine, context) do
    Map.update(engine, :player_tracker, %{}, fn tracker ->
      Map.put(tracker, :active, [
        context.p4,
        context.p5,
        context.p6,
        context.p1,
        context.p2,
        context.p3
      ])
    end)
  end

  @doc """
  Sets up a game with the maximum number of players. The game will
  begin in the pre_flop phase with all players holding 200 chips,
  cards have been dealt out to all players, and the seating and active
  player tracker lists have been filled. Roles will have been set, and
  blinds will have been paid.
  """
  def setup_multiplayer_game(context) do
    setup_cards_and_deck(context)
    |> Map.put(:player_tracker, insert_active_players(context))
    |> Map.put(:chips, add_200_chips_for_all(context))
    |> Map.put(:phase, :pre_flop)
    |> setup_roles()
    |> setup_chips(context)
    |> cycle_to_first_move(context)
  end
end
