defmodule PokerEx.AuthController do
  @moduledoc """
  Gives users the option to sign in via Facebook 
  and other strategies
  """
  
  use PokerEx.Web, :controller
  alias Ueberauth.Strategy.Helpers
  require Logger
  plug Ueberauth
  
  def request(conn, _params) do
    render(conn, "request.html", callback_url: Helpers.callback_url(conn))
  end
  
  def callback(%{assigns: %{ueberauth_failure: fail}} = conn, params) do
    Logger.info "Auth callback received with conn:\n#{inspect(fail)}\nand params: #{inspect(params)}"
    redirect(conn, to: "/")
  end
  
  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    user_info = auth.extra.raw_info.user
    case Repo.get_by(PokerEx.Player, email: user_info["email"]) do
      %PokerEx.Player{} = player ->
        login_and_redirect(%{conn: conn, message: "Welcome back, #{player.name}", player: player})
      _ ->
        maybe_insert_player(conn, user_info)
    end
  end
  
  defp login_and_redirect(%{conn: conn, message: message, player: player}) do
    conn
      |> PokerEx.Auth.login(player)
      |> put_flash(:info, message)
      |> redirect(to: player_path(conn, :show, player.id))
  end
  
  defp player_params(user_info) do
    %{"name" => user_info["name"], "email" => user_info["email"], "first_name" => user_info["first_name"],
      "last_name" => user_info["last_name"], "blurb" => " ", "facebook_id" => user_info["id"]}
  end
  
  defp maybe_insert_player(conn, user_info) do
    changeset = PokerEx.Player.facebook_reg_changeset(%PokerEx.Player{}, player_params(user_info))
    case Repo.insert(changeset) do
      {:ok, player} ->
        login_and_redirect(%{conn: conn, message: "Welcome to PokerEx, #{player.name}", player: player})
      _error ->
        conn
          |> put_flash(:error, "Signup failed")
          |> redirect(to: "/")
    end
  end
end