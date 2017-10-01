defmodule PokerExWeb.SessionView do
  use PokerExWeb, :view

  def render("login.json", %{jwt: jwt}) do
    {:ok, %{"aud" => user}} = Guardian.decode_and_verify(jwt)
    %{jwt: jwt, id: getId(user)}
  end

  defp getId(user_string) when is_binary user_string do
    user_string
    |> String.split(":")
    |> Enum.drop(1)
    |> hd()
  end
end
