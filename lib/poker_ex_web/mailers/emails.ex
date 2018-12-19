defmodule PokerEx.Emails do
  import Bamboo.Email
  use Bamboo.Phoenix, view: PokerEx.EmailView

  @support_email "support@pokerex.com"

  def welcome_email do
    new_email()
    |> to("zkayser@i.softbank.com")
    |> from("zkayser@gmail.com")
    |> subject("Welcome to PokerEx")
    |> html_body(
      "<strong>Thank you for joining PokerEx! Your account has been registered.</strong>"
    )
    |> text_body("Welcome to PokerEx.")
  end

  def welcome_email(user) do
    new_email()
    |> to(user.email)
    |> from(@support_email)
    |> subject("Welcome to PokerEx, #{user.name}!")
    |> html_body("<h1>Thank you for joining PokerEx!</h1>
        <p><strong>We wish you the best of luck out there!</strong></p>")
    |> text_body("Thank you for joining PokerEx! We wish you the best of luck out there!")
  end

  def password_reset(%PokerEx.Player{} = player) do
    new_email()
    |> to(player.email)
    |> from(@support_email)
    |> subject("Password Reset Link")
    |> assign(:player, player)
    |> render(:password_reset)
  end

  def invitation_email(options) when is_map(options) do
    new_email()
    |> to(options["email_address"])
    |> from(options["user"].email)
    |> subject("#{options["user"].first_name} has invited you to PokerEx")
    |> html_body(invitation_html(options))
    |> text_body(invitation_text(options))
  end

  defp invitation_html(options) do
    "
      <h3>
        <strong>
          Hey there, #{options["user"].first_name} has invited you to join PokerEx for and
          friendly game of Texas Hold 'Em.
        </strong>
      </h3>
      <p>#{options["message"]}</p>

      <p>
        Come join PokerEx and enjoy some good 'ole poker with friends by visiting us.
        <a href=#{"https://ancient-forest-15148.herokuapp.com"}>Take me to PokerEx!</a>
      </p>
    "
  end

  defp invitation_text(options) do
    "Greetings from #{options["user"].first_name} and PokerEx! \n#{options["message"]}\n
     You can find #{options["user"].first_name} on PokerEx by searching for #{
      options["user"].name
    } from your account page.
    "
  end
end
