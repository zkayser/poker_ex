defmodule PokerExWeb.Support.ApiHelpers do
  import Phoenix.Controller
  import Plug.Conn
  alias PokerEx.Repo

  @default_login_method &PokerExWeb.Auth.login_by_username_and_pass/4
  @unauthorized_message "Unauthorized"

  @type credentials ::
          String.t()
          | %{optional(:facebook_id) => String.t()}
          | %{optional(:google_id) => String.t()}
  @type login_function :: (... -> login_success | login_failure)
  @type login_failure ::
          {:error, :unauthorized, %Plug.Conn{}}
          | {:error, :not_found, %Plug.Conn{}}
          | {:error, :oauth_error, %Plug.Conn{}}
  @type login_success :: {:ok, %Plug.Conn{}}

  @spec api_sign_in(%Plug.Conn{}, String.t(), credentials, login_function) :: %Plug.Conn{}
  def api_sign_in(conn, username, pass_or_oauth, login \\ @default_login_method) do
    with {:ok, conn} <- login.(conn, username, pass_or_oauth, repo: Repo) do
      new_conn = Guardian.Plug.sign_in(conn, PokerEx.Auth.Guardian, conn.assigns[:current_player])
      jwt = Guardian.Plug.current_token(new_conn)
      claims = Guardian.Plug.current_claims(new_conn)
      expiration = Map.get(claims, "exp")

      new_conn
      |> put_resp_header("authorization", "Bearer #{jwt}")
      |> put_resp_header("x-expires", "#{expiration}")
      |> put_view(PokerExWeb.SessionView)
      |> render("login.json", jwt: jwt)
    else
      _ -> conn |> put_status(:unauthorized) |> json(%{message: @unauthorized_message})
    end
  end
end
