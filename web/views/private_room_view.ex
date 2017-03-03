defmodule PokerEx.PrivateRoomView do
  use PokerEx.Web, :view
  
  def zip_list(list) when is_list(list) do
    size = length(list)
    ~w(purple teal red blue yellow green)
    |> Stream.cycle
    |> Enum.take(size)
    |> Enum.zip(list)
  end
end