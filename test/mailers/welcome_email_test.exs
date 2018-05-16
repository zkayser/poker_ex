defmodule PokerEx.WelcomeMailerTest do
  use ExUnit.Case
  import PokerEx.TestHelpers
  alias PokerEx.{Emails, Repo}

  @welcome_string "Thank you for joining PokerEx!"

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

    {:ok, user: insert_user()}
  end

  test "welcome email", context do
    email = Emails.welcome_email(context.user)

    assert email.to == context.user.email
    assert email.from == "support@pokerex.com"
    assert email.subject =~ "Welcome to PokerEx, #{context.user.name}"
    assert email.html_body =~ @welcome_string
  end
end
