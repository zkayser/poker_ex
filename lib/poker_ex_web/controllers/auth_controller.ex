defmodule PokerExWeb.AuthController do
  @moduledoc """
  Gives users the option to sign in via Facebook
  and other strategies
  """
  use PokerExWeb, :controller
  alias PokerExWeb.Auth
  alias PokerEx.MapUtils
  require Logger

  @unauthorized_message "Authorization failed"
  def oauth_handler(conn, %{"name" => _name, "facebook_id" => id} = provider_data) do
    conn =
      case PokerEx.Player.fb_login_or_create(MapUtils.to_atom_keys(provider_data)) do
        %PokerEx.Player{} = player ->
          api_sign_in(conn, player.name, %{facebook_id: id}, &Auth.oauth_login/4)

        _ ->
          unauthorized(conn)
      end

    conn
  end

  def oauth_handler(conn, %{"email" => email, "google_token_id" => token}) do
    with {:ok, google_id} <- PokerEx.Auth.Google.validate(token) do
      case PokerEx.Player.google_login_or_create(%{email: email, google_id: google_id}) do
        %PokerEx.Player{} = player ->
          api_sign_in(conn, player.name, %{google_id: player.google_id}, &Auth.oauth_login/4)

        _ ->
          unauthorized(conn)
      end
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
end
