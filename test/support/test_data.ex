defmodule PokerEx.TestData do
  alias PokerEx.GameEngine.Impl, as: Engine
  alias PokerEx.GameEngine.{ChipManager, PlayerTracker, Seating, CardManager}
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
    names = for player <- [p1, p2, p3, p4, p5, p6], do: player.name
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
        {player.name, seat}
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
end
