defmodule PokerEx.Emails do
  import Bamboo.Email
  use Bamboo.Phoenix, view: PokerEx.EmailView
  
  def welcome_email do
    new_email()
    |> to("zkayser@i.softbank.com")
    |> from("zkayser@gmail.com")
    |> subject("Welcome to PokerEx")
    |> html_body("<strong>Thank you for joining PokerEx! Your account has been made</strong>")
    |> text_body("Welcome to PokerEx.")
  end
  
  def welcome_text_email(email_address) do
    new_email()
    |> to(email_address)
    |> from("us@example.com")
    |> subject("Welcome!")
    |> text_body("Welcome to PokerEx!")
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
     You can find #{options["user"].first_name} on PokerEx by searching for #{options["user"].name} from your account page.
    "
  end
end