defmodule PokerEx.RoomCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import PokerEx.TestHelpers
      alias PokerEx.Room
      alias PokerEx.Player
      alias PokerEx.Repo
      alias PokerEx.RoomsSupervisor, as: RoomSup
    end
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(PokerEx.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(PokerEx.Repo, {:shared, self()})
    test_room = "test#{Base.encode16(:crypto.strong_rand_bytes(8))}"

    try do
      PokerEx.RoomsSupervisor.create_private_room(test_room)
    catch
      _, _ ->
        PokerEx.Application.stop([])
        Application.ensure_all_started(PokerEx)
        PokerEx.Application.start(:normal, [])
        PokerEx.RoomsSupervisor.create_private_room("test")
    end

    [p1, p2, p3, p4] =
      for _ <- 1..4 do
        PokerEx.TestHelpers.insert_user()
      end
    |> Enum.map(fn player -> player end)

    # on_exit fn -> Process.exit(Process.whereis(String.to_atom(test_room)), :kill) end

    [p1: p1, p2: p2, p3: p3, p4: p4, test_room: test_room]
  end
end
