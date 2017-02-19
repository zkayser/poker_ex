defmodule PokerEx.OnlineChannel do
  use Phoenix.Channel
  
  def join("online:lobby", _message, socket) do
    send(self(), :after_join)
    {:ok, %{}, socket}
  end
  def join("online:" <> _, _, _), do: {:error, %{reason: "unauthorized"}}
  
  def handle_info(:after_join, socket) do
    push socket, "joined", %{}
    {:noreply, socket}
  end

end