defmodule PokerEx.PlayerController do
  use PokerEx.Web, :controller
  plug :authenticate_player when action in [:index, :show]
  
  alias PokerEx.Player
  
  def new(conn, _params) do
    changeset = Player.changeset(%Player{})
    render conn, "new.html", changeset: changeset
  end
  
  def index(conn, _params) do
    players = Repo.all(PokerEx.Player)
    render conn, "index.html", players: players
  end
  
  def show(conn, %{"id" => player_id} = params) do
    {id, _} = Integer.parse(player_id)
    redirect_wrong_user(conn, params)
    
    # player = Repo.get(Player, id)
    player = Repo.one(
      from p in Player, 
      where: p.id == ^id,
      preload: [:owned_rooms, :received_invitations, :participating_rooms, :invited_rooms]
    )
    
    render conn, "show.html", player: player, owned: player.owned_rooms, 
      invitations: player.received_invitations, participating: player.participating_rooms,
      invited: player.invited_rooms
  end
  
  def edit(conn, %{"id" => player_id}) do
    {id, _} = Integer.parse(player_id)
    player = Repo.get(Player, id)
    changeset = Player.update_changeset(player)
    render conn, "edit.html", changeset: changeset, player: player
  end
  
  def create(conn, %{"player" => player_params}) do
    player_params = Map.put(player_params, "chips", "1000")
    changeset = Player.registration_changeset(%Player{}, player_params)
    
    case Repo.insert(changeset) do
      {:ok, player} ->
        conn
        |> PokerEx.Auth.login(player)
        |> put_flash(:info, "#{player.name} created!")
        |> redirect(to: room_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
  
  def update(conn, %{"player" => player_params, "id" => player_id}) do
    player = Repo.get(Player, player_id)
    changeset = Player.update_changeset(player, player_params)
    
    case Repo.insert(changeset) do
      {:ok, player} ->
        conn
        |> put_flash(:info, "Successfully updated")
        |> redirect(to: player_path(conn, :show, player.id))
      {:error, changeset} ->
        render(conn, "edit.html", changeset: changeset, player: player)
    end
  end
  
  defp redirect_wrong_user(conn, %{"id" => player_id}) do
    {id, _} = Integer.parse(player_id)
    unless id == conn.assigns.current_player.id do
      conn
      |> put_flash(:error, "Access restricted")
      |> redirect(to: player_path(conn, :show, conn.assigns.current_player.id))
    end
  end
end