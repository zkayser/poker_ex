defmodule PokerEx.GameEngine.Decoders.Seating do
  alias PokerEx.GameEngine.Seating
  @behaviour PokerEx.GameEngine.Decoder

  def decode(%{} = map), do: decode_from_map(map)
  def decode([]), do: {:ok, %Seating{}}

  def decode(json) do
    with {:ok, value} <- Jason.decode(json) do
      decode_from_map(value)
    else
      _ ->
        {:error, {:decode_failed, Seating}}
    end
  end

  defp decode_from_map(value) do
    arrangement =
      Enum.reduce(value, [], fn map, acc ->
        key = Map.keys(map) |> hd()
        [{key, map[key]} | acc]
      end)
      |> Enum.reverse()

    {:ok, %Seating{arrangement: arrangement}}
  end
end
