defmodule PokerExWeb.RegistrationController do
  use PokerExWeb, :controller

  action_fallback PokerExWeb.FallbackController

  def create(conn, %{"registration" => registration_params}) do
    registration_params = Map.put(registration_params, "chips", "1000")
    registration_params =
      if registration_params["blurb"] == "" do
        Map.put(registration_params, "blurb", " ")
      else
        registration_params
      end
      changeset = PokerEx.Player.registration_changeset(%PokerEx.Player{}, registration_params)

      with {:ok, player} <- PokerEx.Repo.insert(changeset) do
        api_sign_in(conn, registration_params["name"], registration_params["password"])
      end
  end
end
