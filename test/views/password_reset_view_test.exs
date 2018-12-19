defmodule PokerExWeb.PasswordResetViewTest do
  use PokerExWeb.ConnCase, async: true
  import Phoenix.View

  test "renders success.json" do
    json = render(PokerExWeb.PasswordResetView, "success.json", %{})

    expected = %{
      "data" => %{
        "message" => "An email has been sent with a link to reset your password",
        "type" => "success"
      }
    }

    assert json == expected
  end

  test "renders error.json" do
    json = render(PokerExWeb.PasswordResetView, "error.json", %{})

    expected = %{
      "data" => %{
        "message" => "No user exists with the email provided",
        "type" => "error"
      }
    }

    assert json == expected
  end

  test "renders reset_failed.json" do
    json = render(PokerExWeb.PasswordResetView, "reset_failed.json", %{})

    expected = %{
      "data" => %{
        "message" => "Password reset failed. Please re-submit the form and try again",
        "type" => "error"
      }
    }

    assert json == expected
  end
end
