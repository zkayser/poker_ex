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
    
    if id == conn.assigns.current_player.id do
      handle_show(conn, id)
    else
      redirect_wrong_user(conn, params)
    end
  end
  
  def edit(conn, %{"id" => player_id} = _params) do
    {id, _} = Integer.parse(player_id)
    
    player = Repo.get(Player, id)
    changeset = Player.update_changeset(player)
    render conn, "edit.html", changeset: changeset, player: player
  end
  
  def create(conn, %{"player" => player_params}) do
    player_params = Map.put(player_params, "chips", "1000")
    player_params = 
      if player_params["blurb"] == "" do
        Map.put(player_params, "blurb", " ")
      else
        player_params
      end
    changeset = Player.registration_changeset(%Player{}, player_params)
    
    case Repo.insert(changeset) do
      {:ok, player} ->
        conn
        |> PokerEx.Auth.login(player)
        |> put_flash(:info, "#{player.name} created!")
        |> redirect(to: player_path(conn, :show, player.id))
      {:error, changeset} ->
        conn
        |> put_flash(:error, "Oops, something went wrong! Please check the errors below.")
        |> redirect(to: player_path(conn, :new))
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
  
  def list(conn, %{"player" => player, "page" => page}) do
    query = 
      from p in PokerEx.Player,
        where: p.name != ^player,
        order_by: [asc: :id],
        select: [p.id, p.name, p.blurb]
    page = Repo.all(query) |> Repo.paginate(%{page: page})
    render(conn, "player_list.json", players: page.entries, current_page: page.page_number, total: page.total_pages)
  end
  
  defp redirect_wrong_user(conn, %{"id" => player_id}) do
    {id, _} = Integer.parse(player_id)
    if conn.assigns.current_player do
      conn
      |> put_flash(:error, "Access restricted")
      |> redirect(to: player_path(conn, :show, conn.assigns.current_player.id))
    else
      conn
      |> put_flash(:error, "You must be logged in")
      |> redirect(to: page_path(conn, :index))
    end
  end
  
  defp handle_show(conn, id) do
    player = Repo.one(
      from p in Player, 
      where: p.id == ^id,
      preload: [:owned_rooms, :received_invitations, :participating_rooms, :invited_rooms]
    )
    
    render conn, "show.html", player: player, owned: player.owned_rooms, 
      invitations: player.received_invitations, participating: player.participating_rooms,
      invited: player.invited_rooms
  end
end