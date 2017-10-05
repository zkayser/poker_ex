defmodule PokerExWeb.SessionController do
  use PokerExWeb, :controller

  action_fallback PokerExWeb.FallbackController

  def new(conn, _) do
    render conn, "new.html"
  end

  def create(conn, %{"session" => %{"name" => player, "password" => pass}}) do
    case PokerExWeb.Auth.login_by_username_and_pass(conn, player, pass, repo: Repo) do
      {:ok, conn} ->
        conn
        |> put_flash(:info, "Welcome back!")
        |> redirect(to: player_path(conn, :show, Repo.get_by(PokerEx.Player, name: player).id))
      {:error, _reason, conn} ->
        conn
        |> put_flash(:error, "Invalid username/password combination")
        |> render("new.html")
    end
  end

  # API sign-ins
  def create(conn, %{"player" => %{"username" => username, "password" => pass}}) do
    with {:ok, conn} <- PokerExWeb.Auth.login_by_username_and_pass(conn, username, pass, repo: Repo) do
      new_conn = Guardian.Plug.api_sign_in(conn, conn.assigns[:current_player])
      jwt = Guardian.Plug.current_token(new_conn)
      {:ok, claims} = Guardian.Plug.claims(new_conn)
      expiration = Map.get(claims, "exp")

      new_conn
      |> put_resp_header("authorization", "Bearer #{jwt}")
      |> put_resp_header("x-expires", "#{expiration}")
      |> render("login.json", jwt: jwt)
    end
  end

  def delete(conn, _) do
    conn
    |> PokerExWeb.Auth.logout()
    |> redirect(to: page_path(conn, :index))
  end
end
