defmodule PokerExWeb.PrivateRoomController do
  use PokerExWeb, :controller
  alias PokerEx.PrivateRoom

  def new(conn, _params) do
    changeset = PrivateRoom.changeset(%PrivateRoom{invitees: [], owner: nil}, %{})

    query =
      from(
        p in PokerEx.Player,
        where: p.id != ^conn.assigns[:current_player].id,
        order_by: [asc: :id],
        select: [p.id, p.name, p.blurb]
      )

    players = Repo.all(query)
    page = Repo.all(query) |> Repo.paginate()
    render(conn, "new.html", changeset: changeset, players: players, page: page)
  end

  def show(conn, %{"id" => id}) do
    room = PokerEx.Repo.get(PrivateRoom, String.to_integer(id))
    do_show(conn, room)
  end

  defp authenticate(conn, room) do
    player = conn.assigns[:current_player]

    unless player in room.invitees || player == room.owner || player in room.participants do
      conn
      |> put_flash(:error, "Access restricted")
      |> redirect(to: Routes.player_path(conn, :show, conn.assigns[:current_player]))
    end
  end

  defp do_show(conn, nil) do
    conn
    |> put_flash(:error, "An error occurred and that room no longer exists")
    |> redirect(to: Routes.player_path(conn, :show, conn.assigns[:current_player]))
  end

  defp do_show(conn, room) do
    room = PrivateRoom.preload(room)
    authenticate(conn, room)

    case maybe_restore_state(room.title) do
      :process_alive ->
        render(conn, "show.html", room: room)

      :ok ->
        render(conn, "show.html", room: room)

      {:error, priv_room} ->
        PrivateRoom.delete(priv_room)

        conn
        |> put_flash(:error, "An error occurred and that room no longer exists.")
        |> redirect(to: Routes.player_path(conn, :show, conn.assigns[:current_player]))
    end
  end

  defp maybe_restore_state(id) do
    pid =
      id
      |> String.to_atom()
      |> Process.whereis()

    unless pid do
      priv_room = PokerEx.Repo.get_by(PrivateRoom, title: id)

      case priv_room.stored_game_data do
        nil ->
          {:error, priv_room}

        game_data when is_binary(game_data) ->
          with {:ok, game_data} <- PokerEx.GameEngine.Impl.decode(game_data) do
            PokerEx.GameEngine.start_link(game_data.game_id)
            PokerEx.GameEngine.put_state(game_data.game_id, game_data)

            :ok
          end

        _ ->
          {:error, priv_room}
      end
    else
      :process_alive
    end
  end
end
