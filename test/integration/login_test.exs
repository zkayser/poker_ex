defmodule LoginTest do
  use PokerEx.IntegrationCase, async: true
  hound_session()
  
  setup _tags do
    player = insert_user()
    navigate_to("/sessions/new")
    %{player: player}
  end
  
  test "non-existent users cannot login" do
    login("non-existent", "user")
    
    assert_alert()
  end
  
  test "A user can log in with a registered name and correct password", %{player: player} do
    login(player.name, "secretpassword")
    
    assert_welcome()
  end
  
  test "Cannot login with a blank username" do
    login("", "secretpassword")
    
    assert_alert()
  end
  
  test "Cannot login with a blank password", %{player: player} do
    login(player.name, "")
    
    assert_alert()
  end
  
  ## Helpers
  
  defp assert_text(strategy, selector, expected) do
    actual = get_text(strategy, selector)
    assert actual =~ expected
  end
  
  defp assert_alert() do
    assert_text(:class, "alert-danger", "Invalid username/password combination")
  end
  
  defp assert_welcome() do
    assert_text(:class, "alert-info", "Welcome back")
  end
  
  defp login(name, password) do
    find_element(:id, "session_name")
    |> fill_field(name)
    
    find_element(:id, "session_password")
    |> fill_field(password)
    
    find_element(:id, "signup-button")
    |> click()
  end
end