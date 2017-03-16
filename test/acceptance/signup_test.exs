defmodule SignupTest do
  use PokerEx.IntegrationCase, async: true
  hound_session()
  
  @valid_attrs %{
    first_name: "User",
    last_name: "Person",
    name: "user#{Base.encode16(:crypto.strong_rand_bytes(8))}",
    email: "email#{Base.encode16(:crypto.strong_rand_bytes(8))}",
    blurb: " ",
    password: "secretpassword"
  }
  
  @invalid_attrs %{
    name: "",
    email: "",
    password: ""
  }
  
  setup _tags do
    navigate_to("/players/new")
    :ok
  end
  
  test "A user can signup with valid attrs and is redirected to the player profile page" do
    valid_signup()
    assert_created()
    assert current_path() =~ ~r(players/\d+)
  end
  
  test "Invalid when username, email, and password are blank" do
    invalid_signup_with([:name, :email, :password])
    assert_alert()
    refute_redirected()
  end
  
  test "Invalid when username is left blank" do
    invalid_signup_with([:name])
    assert_alert()
    refute_redirected()
  end
  
  test "Invalid when email is left blank" do
    invalid_signup_with([:email])
    assert_alert()
    refute_redirected()
  end
  
  test "Invalid when password is left blank" do
    invalid_signup_with([:password])
    assert_alert()
    refute_redirected()
  end
  
  test "Invalid when username already exists" do
    player = insert_user()
    for id <- Map.from_struct(player) |> Map.take([:name, :first_name, :last_name, :email, :blurb]) |> Map.keys() do
      string_id = "player_" <> Atom.to_string(id)
      find_element(:id, string_id)
      |> fill_field(Map.from_struct(player)[id])
    end
    find_element(:id, "player_password")
    |> fill_field("secretpassword")
    find_element(:id, "signup-button") |> click()
    assert_alert()
    refute_redirected()
  end
  
  ###########
  # Helpers #
  ###########
  
  defp valid_signup do
    fill_valid_fields()
    find_element(:id, "signup-button") |> click()
  end
  
  defp invalid_signup_with(attrs) when is_list(attrs) do
    fill_valid_fields()
    for attr <- attrs do
      string_id = "player_" <> Atom.to_string(attr)
      find_element(:id, string_id)
      |> fill_field(@invalid_attrs[attr])
    end
    find_element(:id, "signup-button") |> click()
  end
  
  defp fill_valid_fields() do
    for id <- Map.keys(@valid_attrs) do
      string_id = "player_" <> Atom.to_string(id)
      find_element(:id, string_id)
      |> fill_field(@valid_attrs[id])
    end
  end
  
  defp assert_text(strategy, selector, expected) do
    actual = get_text(strategy, selector)
    assert actual =~ expected
  end
  
  defp assert_alert() do
    assert_text(:class, "alert-danger", "Oops, something went wrong! Please check the errors below")
  end
  
  defp assert_created() do
    assert_text(:class, "alert-info", " created")
  end
  
  defp refute_redirected() do
    assert current_path() =~ ~r(players/new)
  end
end