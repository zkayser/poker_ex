defmodule PokerEx.GameEngine.GamesServerTest do
  use ExUnit.Case
  alias PokerEx.GameEngine.GamesServer

  @initial_game_count Application.get_env(PokerEx, :initial_game_count)

  test "it exists" do
    assert Process.whereis(GamesServer) |> Process.alive?()
  end

  test "get_games returns a list of games running on the server" do
    assert length(GamesServer.get_games()) == @initial_game_count
  end
end
