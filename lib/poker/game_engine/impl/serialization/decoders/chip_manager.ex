defmodule PokerEx.GameEngine.Decoders.ChipManager do
  alias PokerEx.GameEngine.ChipManager
  @behaviour PokerEx.GameEngine.Decoder

  def decode(%{} = map), do: decode_from_map(map)

  def decode(json) do
    with {:ok, value} <- Jason.decode(json) do
      decode_from_map(value)
    else
      _ -> {:error, {:decode_failed, ChipManager}}
    end
  end

  defp decode_from_map(map) do
    {:ok,
     %ChipManager{
       chip_roll: map["chip_roll"],
       paid: map["paid"],
       pot: map["pot"],
       round: map["round"],
       to_call: map["to_call"]
     }}
  end
end
