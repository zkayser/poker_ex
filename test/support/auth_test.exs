defmodule PokerExWeb.AuthTest do
  use ExUnit.Case, async: false
  alias PokerEx.Repo
  alias PokerExWeb.Auth

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
  end

  test "check_oauth/2 returns true when the given oauth data is contained inside of the player struct" do
    oauth_data = %{facebook_id: "1234"}
    name = "User#{Base.encode16(:crypto.strong_rand_bytes(8))}"
    {:ok, _player} = Repo.insert(%PokerEx.Player{name: name, facebook_id: oauth_data.facebook_id})
    assert Auth.check_oauth(name, oauth_data.facebook_id)
  end

  test "check_oauth/2 returns false when the player struct does not contain the oauth value given" do
    oauth_data = %{facebook_id: "not_valid"}
    name = "User#{Base.encode16(:crypto.strong_rand_bytes(8))}"
    {:ok, _} = Repo.insert(%PokerEx.Player{name: name, chips: 1000})
    refute Auth.check_oauth(name, oauth_data.facebook_id)
  end

  test "oauth_login/4 should return :oauth_error when the oauth_provider given is invalid" do
    # Currently, only :facebook_id and :google_id (which is not yet implemented) are
    # defined as valid oauth_providers in the Auth @valid_oauth_providers module attribute
    {oauth_data, opts} = {%{invalid_provider: "nonsense"}, [repo: Repo]}

    assert {:error, :oauth_error, _} =
             Auth.oauth_login(%Plug.Conn{}, "some username", oauth_data, opts)
  end

  test "oauth_login/4 should return :oauth_error when more than one oauth_provider is given" do
    {oauth_data, opts} = {%{facebook_id: "1234", google_id: "5678"}, [repo: Repo]}

    assert {:error, :oauth_error, _} =
             Auth.oauth_login(%Plug.Conn{}, "some username", oauth_data, opts)
  end
end
