defmodule PokerEx.Auth.GoogleTest do
  use ExUnit.Case
  alias PokerEx.Auth.Google
  @token System.get_env("GOOGLE_TOKEN")

  setup do
    Application.put_env(:poker_ex, :expiration_validator, &expiration_validator/2)

    on_exit(fn ->
      Application.put_env(:poker_ex, :expiration_validator, &DateTime.compare/2)
    end)

    :ok
  end

  describe "validate/1" do
    test "returns ok if the token signature can be verified" do
      IO.inspect(@token, label: "TOKEN")
      assert {:ok, google_id} = Google.validate(@token)
      assert is_binary(google_id)
    end

    test "returns unauthorized error if the token signature cannot be verified" do
      fake_token = String.replace_trailing(@token, String.last(@token), "a")
      assert {:error, :unauthorized} = Google.validate(fake_token)
    end

    test "returns unauthorized error if the an invalid token is given" do
      assert {:error, :unauthorized} = Google.validate("some_fake_token")
    end

    test "retries if the cache value has expired" do
      {:ok, body} = Jason.decode(Google.FakeCerts.get().body)

      :ets.insert(
        :cache,
        {:google_certs, body, DateTime.add(DateTime.utc_now(), -(24 * 60 * 60), :second)}
      )

      assert {:ok, google_id} = Google.validate(@token)
      assert is_binary(google_id)
    end

    test "returns unauthorized error if the token is expired" do
      Application.put_env(:poker_ex, :expiration_validator, &DateTime.compare/2)

      assert {:error, :unauthorized} = Google.validate(@token)
    end
  end

  defp expiration_validator(_, _), do: :lt
end
