defmodule PokerEx.Auth do
  import Plug.Conn
  import Phoenix.Controller
  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]
  alias PokerEx.Router.Helpers
  
  def init(opts) do
    Keyword.fetch!(opts, :repo)
  end
  
  def call(conn, repo) do
    player_id = get_session(conn, :player_id)
    
    cond do
      player = conn.assigns[:current_player] ->
        put_current_player(conn, player)
      player = player_id && repo.get(PokerEx.Player, player_id) ->
        put_current_player(conn, player)
      true ->
        assign(conn, :current_player, nil)
    end
  end
  
  def login(conn, player) do
    conn
    |> put_current_player(player)
    |> put_session(:player_id, player.id)
    |> configure_session(renew: true)
  end
  
  defp put_current_player(conn, player) do
    token = Phoenix.Token.sign(conn, "user socket", player.id)
    
    conn
    |> assign(:current_player, player)
    |> assign(:player_token, token)
  end
  
  def login_by_username_and_pass(conn, username, given_pass, opts) do
    repo = Keyword.fetch!(opts, :repo)
    player = repo.get_by(PokerEx.Player, name: username)
    
    cond do
      player && checkpw(given_pass, player.password_hash) ->
        {:ok, login(conn, player)}
      player ->
        {:error, :unauthorized, conn}
      true ->
        dummy_checkpw()
        {:error, :not_found, conn}
    end
  end
  
  def logout(conn) do
    configure_session(conn, drop: true)
  end
  
  def authenticate_player(conn, _opts) do
    if conn.assigns.current_player do
      conn
    else
      conn
      |> put_flash(:error, "You must be logged in to access that page")
      |> redirect(to: Helpers.page_path(conn, :index))
      |> halt()
    end
  end
end