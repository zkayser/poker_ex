defmodule PokerEx.UpdaterTest do
  use ExUnit.Case
  alias PokerEx.Room.Updater
  alias PokerEx.Room
  
  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(PokerEx.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(PokerEx.Repo, {:shared, self()})
    
    :ok
  end
  
  doctest Updater
end