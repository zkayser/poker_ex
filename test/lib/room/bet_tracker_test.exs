defmodule PokerEx.BetTrackerTest do
  use ExUnit.Case
  alias PokerEx.Room
  alias PokerEx.Room.BetTracker
  alias PokerEx.Player
  
  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(PokerEx.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(PokerEx.Repo, {:shared, self()})
    
    a = Player.registration_changeset(%Player{}, %{
      "name" => "A",
      "password" => "password",
      "email" => "A@email.com",
      "first_name" => "A",
      "last_name" => "B"
    })
    PokerEx.Repo.insert(a)
    
    b = Player.registration_changeset(%Player{}, %{
      "name" => "B",
      "password" => "password",
      "email" => "B@email.com",
      "first_name" => "B",
      "last_name" => "C"
    })
    PokerEx.Repo.insert(b)
    :ok
  end
  
  doctest BetTracker
end