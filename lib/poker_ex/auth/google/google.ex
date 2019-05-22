defmodule PokerEx.Auth.Google do
  alias :ets, as: ETS
  @jwks_endpoint "https://www.googleapis.com/oauth2/v3/certs"
  @cache :cache
  @certs_key :google_certs
  @certs_module Application.get_env(:poker_ex, :google_certs_module)
  @client_id System.get_env("GOOGLE_CLIENT_ID_POKER_EX")
  @google_issuer "accounts.google.com"
  @max_age_regex ~r/max-age=(\d+)/

  @type result :: :ok | {:error, :request_failed | :unauthorized}
  @type json_web_token :: String.t()

  @spec validate(json_web_token) :: result
  def validate(token) do
    case ETS.lookup(@cache, @certs_key) do
      [] ->
        get_certs()
        |> validate_(token)

      [{_, certs_response, datetime}] ->
        if should_validate?(datetime) do
          validate_(certs_response, token)
        else
          ETS.delete_all_objects(@cache)
          validate(token)
        end
    end
  end

  defp retry(token) do
    get_certs()
    |> retry_validate(token)
  end

  defp should_validate?(datetime) do
    case DateTime.compare(datetime, DateTime.utc_now()) do
      :gt -> false
      _ -> true
    end
  end

  defp validate_(body, token) do
    with :ok <- validate_signature(body, token),
         true <- is_token_valid?(token) do
      :ok
    else
      false ->
        {:error, :unauthorized}

      error ->
        error
    end
  end

  defp validate_(:error, _), do: {:error, :request_failed}

  defp retry_validate(body, token) do
    with {:ok, kid} <- peek_header(token),
         [key_map] <- Enum.filter(body["keys"], fn key -> key["kid"] == kid end),
         {true, _, _} <- JOSE.JWK.from(key_map) |> JOSE.JWS.verify(token) do
      :ok
    else
      _ ->
        {:error, :unauthorized}
    end
  end

  defp retry_validate(:error, _), do: {:error, :request_failed}

  defp validate_signature(body, token) do
    with {:ok, kid} <- peek_header(token),
         [key_map] <- Enum.filter(body["keys"], fn key -> key["kid"] == kid end),
         {true, _, _} <- JOSE.JWK.from(key_map) |> JOSE.JWS.verify(token) do
      :ok
    else
      {:error, _, _} ->
        {:error, :unauthorized}

      {false, _, _} ->
        ETS.delete_all_objects(@cache)

        case retry(token) do
          :ok -> :ok
          _ -> {:error, :unauthorized}
        end

      error ->
        error
    end
  end

  defp is_token_valid?(
         token,
         expiration_validator \\ Application.get_env(:poker_ex, :expiration_validator)
       ) do
    claims = Guardian.peek_claims(token)
    {:ok, unix_time} = DateTime.from_unix(claims["exp"])

    claims["aud"] == @client_id && String.contains?(claims["iss"], @google_issuer) &&
      :lt == expiration_validator.(DateTime.utc_now(), unix_time)
  end

  defp peek_header(token) do
    try do
      {:ok, Guardian.peek_header(token)["kid"]}
    rescue
      _ -> {:error, :unauthorized}
    end
  end

  defp get_certs do
    response = @certs_module.get()

    case HTTPotion.Response.success?(response) do
      true ->
        {:ok, body} = Jason.decode(response.body)
        ETS.insert(@cache, {@certs_key, body, set_cache_until(response.headers["cache-control"])})
        body

      false ->
        :error
    end
  end

  defp set_cache_until(cache_control) when is_binary(cache_control) do
    with [_, seconds] <- Regex.run(@max_age_regex, cache_control) do
      DateTime.add(DateTime.utc_now(), String.to_integer(seconds), :second)
    else
      _ -> DateTime.utc_now()
    end
  end
end
