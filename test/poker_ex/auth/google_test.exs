defmodule PokerEx.Auth.GoogleTest do
  use ExUnit.Case
  alias PokerEx.Auth.Google
  @token System.get_env("GOOGLE_TOKEN")

  describe "validate/1" do
    test "returns ok if the token signature can be verified" do
      assert :ok = Google.validate(@token)
    end

    test "returns unauthorized error if the token signature cannot be verified" do
      fake_token = String.replace_trailing(@token, String.last(@token), "a")
      assert {:error, :unauthorized} = Google.validate(fake_token)
    end

    test "returns unauthorized error if the an invalid token is given" do
      assert {:error, :unauthorized} = Google.validate("some_fake_token")
    end

    test "retries if that cache value has expired" do
      {:ok, body} = Jason.decode(Google.FakeCerts.get().body)
      :ets.insert(:cache, {:google_certs, body, DateTime.add(DateTime.utc_now(), -(24 * 60 * 60), :second)})
      assert :ok = Google.validate(@token)
    end
  end
end
