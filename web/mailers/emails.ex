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
end