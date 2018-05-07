defmodule PokerExWeb.RoomController do
  use PokerExWeb, :controller
  alias PokerEx.GameEngine.GamesSupervisor, as: GamesSupervisor

  def index(conn, _params) do
    [{pid, _}] = Registry.lookup(PokerEx.GameRegistry, "game_1")
    ids = Registry.keys(PokerEx.GameRegistry, pid)

    {_, room_states} =
      Enum.map_reduce(ids, %{}, fn room, acc ->
        {{room, :state},
         Map.put(acc, String.to_atom(room), PokerEx.GameEngine.get_state(String.to_atom(room)))}
      end)

    render(conn, "index.html", rooms: Map.values(room_states))
  end

  def create(conn, %{"name" => name} = _params) when is_binary(name) do
    case GamesSupervisor.process_exists?(String.to_atom(name)) do
      true ->
        conn
        |> put_flash(:error, "A room with the name #{name} already exists")
        |> redirect(to: player_path(conn, :show, conn.current_player.id))

      _ ->
        conn
        |> put_flash(:info, "Room #{name} created!")
        |> redirect(to: room_path(conn, :show, name))
    end
  end

  def show(conn, %{"id" => name}) do
    room = PokerEx.GameEngine.get_state(name |> String.to_atom())

    render(
      conn,
      "show.html",
      room: room,
      current_player: conn.assigns[:current_player],
      conn: conn
    )
  end
end
