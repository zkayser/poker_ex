defmodule PokerExWeb.AuthController do
  @moduledoc """
  Gives users the option to sign in via Facebook
  and other strategies
  """

  use PokerExWeb, :controller
  alias Ueberauth.Strategy.Helpers
  alias PokerExWeb.Auth
  alias PokerEx.MapUtils
  require Logger
  plug(Ueberauth)

  @unauthorized_message "Authorization failed"

  def request(conn, _params) do
    render(conn, "request.html", callback_url: Helpers.callback_url(conn))
  end

  def callback(%{assigns: %{ueberauth_failure: fail}} = conn, params) do
    Logger.warn(
      "Auth callback received with conn:\n#{inspect(fail)}\nand params: #{inspect(params)}"
    )

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

  def oauth_handler(conn, %{"name" => name, "facebook_id" => id} = provider_data) do
    conn =
      case PokerEx.Player.fb_login_or_create(MapUtils.to_atom_keys(provider_data)) do
        %PokerEx.Player{} = player ->
          api_sign_in(conn, player.name, %{facebook_id: id}, &Auth.oauth_login/4)

        :error ->
          unauthorized(conn)

        :unauthorized ->
          unauthorized(conn)
      end

    conn
  end

  def oauth_handler(conn, %{"email" => _email, "google_token_id" => token} = provider_data) do
    with {:ok, google_id} <- PokerEx.Auth.Google.validate(token) do
      IO.puts("Inside google oauth handler")
      conn
      # case PokerEx.Player.google_login_or_create(MapUtils.to_atom_keys(provider_data)) do
      #   %PokerEx.Player{} = player ->
      #     api_sign_in(conn, player.name, %{google_id: player.google_id}, &Auth.oauth_login/4)

      #   _ ->
      #     unauthorized(conn)
      # end
    else
      {:error, :request_failed} ->
        conn |> put_status(500) |> json(%{message: "Your request failed. Please try again."})

      _ ->
        unauthorized(conn)
    end
  end

  defp unauthorized(conn) do
    conn
    |> put_status(:unauthorized)
    |> json(%{message: @unauthorized_message})
  end

  defp login_and_redirect(%{conn: conn, message: message, player: player}) do
    conn
    |> PokerExWeb.Auth.login(player)
    |> put_flash(:info, message)
    |> redirect(to: player_path(conn, :show, player.id))
  end

  defp player_params(user_info) do
    %{
      "name" => user_info["name"],
      "email" => user_info["email"],
      "first_name" => user_info["first_name"],
      "last_name" => user_info["last_name"],
      "blurb" => " ",
      "facebook_id" => user_info["id"]
    }
  end

  defp maybe_insert_player(conn, user_info) do
    changeset = PokerEx.Player.facebook_reg_changeset(%PokerEx.Player{}, player_params(user_info))

    case Repo.insert(changeset) do
      {:ok, player} ->
        login_and_redirect(%{
          conn: conn,
          message: "Welcome to PokerEx, #{player.name}",
          player: player
        })

      _error ->
        conn
        |> put_flash(:error, "Signup failed")
        |> redirect(to: "/")
    end
  end
end
