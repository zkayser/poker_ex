defmodule PokerEx.SessionController do
  use PokerEx.Web, :controller
  
  def new(conn, _) do
    render conn, "new.html"
  end
  
  def create(conn, %{"session" => %{"name" => player, "password" => pass}}) do
    case PokerEx.Auth.login_by_username_and_pass(conn, player, pass, repo: Repo) do
      {:ok, conn} ->
        conn
        |> put_flash(:info, "Welcome back!")
        |> redirect(to: room_path(conn, :index))
      {:error, _reason, conn} ->
        conn
        |> put_flash(:error, "Invalid username/password combination")
        |> render("new.html")
    end
  end
  
  def delete(conn, _) do
    conn
    |> PokerEx.Auth.logout()
    |> redirect(to: page_path(conn, :index))
  end
end