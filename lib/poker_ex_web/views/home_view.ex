defmodule PokerExWeb.HomeView do
  use PokerExWeb, :view

  def title(%{game_id: id}) do
    id
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  def status(%{phase: phase}) do
    phase
    |> Atom.to_string()
    |> String.capitalize()
  end
end
