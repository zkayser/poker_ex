defmodule PokerEx.EngineCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import PokerEx.TestHelpers
      alias PokerEx.{Player, Repo, TestData}
    end
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(PokerEx.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(PokerEx.Repo, {:shared, self()})

    [p1, p2, p3, p4, p5, p6] =
      for _ <- 1..6 do
        PokerEx.TestHelpers.insert_user()
      end
      |> Enum.map(fn player -> player end)

    {:ok, %{p1: p1, p2: p2, p3: p3, p4: p4, p5: p5, p6: p6}}
  end
end
