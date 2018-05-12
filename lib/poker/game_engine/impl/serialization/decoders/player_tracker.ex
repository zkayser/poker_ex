defmodule PokerEx.GameEngine.Decoders.PlayerTracker do
  alias PokerEx.GameEngine.PlayerTracker
  @behaviour PokerEx.GameEngine.Decoder

  def decode(%{} = map), do: decode_from_map(map)

  def decode(json) do
    with {:ok, value} <- Jason.decode(json) do
      decode_from_map(value)
    else
      {:error, _} -> {:error, {:decode_failed, PlayerTracker}}
    end
  end

  defp decode_from_map(value) do
    {:ok,
     %PlayerTracker{
       active: value["active"],
       all_in: value["active"],
       folded: value["active"],
       called: value["called"]
     }}
  end
end
