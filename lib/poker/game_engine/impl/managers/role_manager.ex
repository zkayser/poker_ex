defmodule PokerEx.GameEngine.RoleManager do
  @type role :: :dealer | :big_blind | :small_blind | :none
  @type seat_position :: 0..6 | :unset
  @type t() :: %__MODULE__{
          dealer: seat_position,
          big_blind: seat_position,
          small_blind: seat_position
        }

  @derive Jason.Encoder
  defstruct dealer: :unset,
            big_blind: :unset,
            small_blind: :unset

  def new do
    %__MODULE__{}
  end

  @spec manage_roles(PokerEx.GameEngine.Impl.t()) :: t()
  def manage_roles(%{seating: seating}) do
    [{_, dealer}, {_, small_blind}, {_, big_blind}] =
      Stream.cycle(seating.arrangement) |> Enum.take(3)

    %__MODULE__{dealer: dealer, small_blind: small_blind, big_blind: big_blind}
  end

  @spec decode(String.t()) :: {:ok, t} | {:error, :decode_failed}
  def decode(%{} = map), do: decode_from_map(map)

  def decode(json) do
    with {:ok, value} <- Jason.decode(json) do
      decode_from_map(value)
    else
      _ -> {:error, {:decode_failed, __MODULE__}}
    end
  end

  defp decode_from_map(value) do
    {:ok,
     %__MODULE__{
       dealer: parse(value["dealer"]),
       big_blind: parse(value["big_blind"]),
       small_blind: parse(value["small_blind"])
     }}
  end

  defp parse("unset"), do: :unset
  defp parse(value), do: value
end
