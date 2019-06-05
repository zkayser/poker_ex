defmodule PokerExWeb.InvitationController do
  use PokerExWeb, :controller
  alias PokerEx.Emails
  alias PokerEx.Mailer

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"invitation" => params}) do
    params
    |> Map.merge(%{"user" => conn.assigns.current_player})
    |> Emails.invitation_email()
    |> Mailer.deliver_now()

    conn
    |> put_flash(:info, "Message sent")
    |> redirect(to: Routes.player_path(conn, :show, conn.assigns.current_player.id))
  end
end
