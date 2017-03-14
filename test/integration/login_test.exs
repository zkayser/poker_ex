defmodule LoginTest do
  use PokerEx.IntegrationCase, async: true
  
  test "A user can log in with a registered name and correct password", %{session: session} do
    visit(session, "/sessions/new")
    h1_heading = get_text(session, "h1")
    assert h1_heading =~ ~r(Login)
  end
  
  test "It stays on :new action for non-existent users", %{session: session} do
    session
    |> login("Nonexistent User", "boguspassword")
    
    assert_alert(session)
    assert_message(session, "h1", "Login")
  end
  
  test "It stays on :new action when username is left blank", %{session: session} do
    session
    |> login("", "secretpassword")
    
    assert_alert(session)
    assert_message(session, "h1", "Login")
  end
  
  test "It stays on :new action when password is left blank", %{session: session} do
    player = insert_user()
    session
    |> login(player.name, "")
    
    assert_alert(session)
    assert_message(session, "h1", "Login")
  end
  
  test "It redirects to the player :show path after logging in, provided an existing player", %{session: session} do
    player = insert_user()
    session
    |> login(player.name, "secretpassword")
    
    assert_message(session, "h1", "User Person's Profile")
  end
  
  def assert_message(session, selector, expected) do
    actual = get_text(session, selector)
    assert actual =~ expected
  end
  
  defp assert_alert(session) do
    assert_message(session, ".alert-danger", "Invalid username/password combination")
  end
  
  defp login(session, name, password) do
    session
    |> visit("/sessions/new")
    |> fill_in(Wallaby.Query.text_field("session_name"), with: name)
    |> fill_in(Wallaby.Query.text_field("session_password"), with: password)
    |> click(Wallaby.Query.button("Log in"))
  end
end