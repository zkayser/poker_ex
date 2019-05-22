defmodule PokerEx.Auth.Google.Certs do
  @jwks_endpoint "https://www.googleapis.com/oauth2/v3/certs"

  @spec get :: HTTPotion.Response.t()
  def get do
    HTTPotion.get(@jwks_endpoint)
  end
end
