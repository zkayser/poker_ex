defmodule PokerExWeb.ForgotPasswordController do
  use PokerExWeb, :controller
  alias PokerEx.Player

  def forgot_password(conn, %{"email" => email}) do
    case Player.email_exists?(email) do
      false ->
        conn
        |> put_view(PokerExWeb.PasswordResetView)
        |> render("error.json", %{})

      true ->
        case Player.initiate_password_reset(email) do
          {:ok, player} -> PokerEx.Emails.password_reset(player) |> PokerEx.Mailer.deliver_later()
          :error -> render(PokerExWeb.PasswordResetView, "reset_failed.json", %{})
        end

        conn
        |> put_view(PokerExWeb.PasswordResetView)
        |> render("success.json", %{})
    end
  end
end
