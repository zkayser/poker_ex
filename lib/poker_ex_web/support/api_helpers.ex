defmodule PokerExWeb.Support.ApiHelpers do
  import Phoenix.Controller
  import Plug.Conn
  alias PokerEx.Repo

  @default_login_method &PokerExWeb.Auth.login_by_username_and_pass/4

  def api_sign_in(conn, username, pass, login \\ @default_login_method) do
    with {:ok, conn} <- login.(conn, username, pass, repo: Repo) do
      new_conn = Guardian.Plug.api_sign_in(conn, conn.assigns[:current_player])
      jwt = Guardian.Plug.current_token(new_conn)
      {:ok, claims} = Guardian.Plug.claims(new_conn)
      expiration = Map.get(claims, "exp")

      new_conn
      |> put_resp_header("authorization", "Bearer #{jwt}")
      |> put_resp_header("x-expires", "#{expiration}")
      |> render(PokerExWeb.SessionView, "login.json", jwt: jwt)
    end
  end
end
