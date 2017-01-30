defmodule PokerEx.PlayerController do
  use PokerEx.Web, :controller
  alias PokerEx.Player
  
  def new(conn, _params) do
    changeset = Player.changeset(%Player{})
    render conn, "new.html", changeset: changeset
  end
  
  def create(conn, %{"player" => player_params}) do
    player_params = Map.put(player_params, "chips", "1000")
    changeset = Player.changeset(%Player{}, player_params)
    
    case Repo.insert(changeset) do
      {:ok, player} ->
        conn
        |> put_flash(:info, "#{player.name} created!")
        |> redirect(to: page_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

end