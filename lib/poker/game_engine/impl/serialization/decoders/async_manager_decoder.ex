defmodule PokerEx.GameEngine.Decoders.AsyncManager do
  alias PokerEx.GameEngine.AsyncManager
  @behaviour PokerEx.GameEngine.Decoder

  @doc """
  Deserializes an async manager struct from a JSON value
  """
  def decode(%{} = map) do
    decode_from_map(map)
  end

  def decode(json) do
    IO.puts("Decoding json #{inspect(json)}")

    with {:ok, value} <- Jason.decode(json) do
      decode_from_map(value)
    else
      _ -> {:error, {:decode_failed, AsyncManager}}
    end
  end

  defp decode_from_map(map) do
    chip_queue =
      for {key, value} <- map["chip_queue"] do
        {key, value}
      end

    {:ok,
     %AsyncManager{cleanup_queue: map["cleanup_queue"], chip_queue: Enum.reverse(chip_queue)}}
  end
end
