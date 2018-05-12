defmodule PokerEx.GameEngine.Decoders.RoleManager do
  alias PokerEx.GameEngine.RoleManager
  @behaviour PokerEx.GameEngine.Decoder

  def decode(%{} = map), do: decode_from_map(map)

  def decode(json) do
    with {:ok, value} <- Jason.decode(json) do
      decode_from_map(value)
    else
      _ -> {:error, {:decode_failed, RoleManager}}
    end
  end

  defp decode_from_map(value) do
    {:ok,
     %RoleManager{
       dealer: parse(value["dealer"]),
       big_blind: parse(value["big_blind"]),
       small_blind: parse(value["small_blind"])
     }}
  end

  defp parse("unset"), do: :unset
  defp parse(value), do: value
end
