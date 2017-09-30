defmodule PokerExWeb.OnlineChannel do
  use Phoenix.Channel
  import Ecto.Query
  alias PokerEx.Player
  alias PokerEx.Repo

  def join("online:lobby", _message, socket) do
    send(self(), :after_join)
    {:ok, %{}, socket}
  end
  def join("online:search", _message, socket) do
    {:ok, %{}, socket}
  end
  def join("online:" <> _, _, _), do: {:error, %{reason: "unauthorized"}}

  def handle_info(:after_join, socket) do
    push socket, "joined", %{}
    {:noreply, socket}
  end

  def handle_in("player_search", %{"value" => value}, socket) do
    query = from p in Player, where: ilike(p.name, ^value)
    response =
      case Repo.all(query) do
        [] -> %{}
        list when is_list(list) ->
          Enum.map(list, fn player -> %{name: player.name, id: player.id, blurb: player.blurb} end)
        _ -> "Error finding player"
      end
    {:reply, {:ok, %{results: response}}, socket}
  end
end
