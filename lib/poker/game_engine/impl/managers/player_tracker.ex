defmodule PokerEx.GameEngine.PlayerTracker do
  alias PokerEx.{Player, Card}
  @type tracker :: [String.t() | Player.t()] | []
  @type hands :: [{String.t(), [Card.t()]}] | []
  @settable_rounds [:idle, :between_rounds]
  @type phase :: :idle | :pre_flop | :flop | :turn | :river | :game_over | :between_rounds

  @type t :: %__MODULE__{
          active: tracker,
          called: tracker,
          all_in: tracker,
          folded: tracker,
          hands: hands
        }

  defstruct active: [],
            called: [],
            all_in: [],
            folded: [],
            hands: []

  def new do
    %__MODULE__{}
  end

  @spec set_active_players(PokerEx.GameEngine.Impl.t(), phase) :: PokerEx.GameEngine.Impl.t()
  def set_active_players(%{seating: seating} = engine, phase) do
    with true <- phase in @settable_rounds,
         true <- length(seating.arrangement) >= 2 do
      %{engine | player_tracker: set_active(seating.arrangement)}
    else
      _ ->
        engine
    end
  end

  defp set_active(arrangement) do
    %__MODULE__{active: Enum.map(arrangement, fn {name, _} -> name end)}
  end
end
