defmodule PokerEx.GameEngine.RoleManager do
  @type role :: :dealer | :big_blind | :small_blind | :none
  @type seat_position :: 0..6 | :game_not_in_progress
  @type t() :: %__MODULE__{
          dealer: seat_position,
          big_blind: seat_position,
          small_blind: seat_position
        }

  defstruct dealer: :unset,
            big_blind: :unset,
            small_blind: :unset

  def new do
    %__MODULE__{}
  end

  @spec manage_roles(PokerEx.GameEngine.Impl.t()) :: t()
  def manage_roles(%{seating: seating, roles: roles} = engine) do
    [{_, dealer}, {_, small_blind}, {_, big_blind}] =
      Stream.cycle(seating.arrangement) |> Enum.take(3)

    %__MODULE__{dealer: dealer, small_blind: small_blind, big_blind: big_blind}
  end
end
