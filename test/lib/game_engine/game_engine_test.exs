defmodule PokerEx.GameEngineTest do
  use ExUnit.Case
  alias PokerEx.GameEngine.Impl, as: Engine
  alias PokerEx.GameEngine.{Seating}
  import PokerEx.TestHelpers

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(PokerEx.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(PokerEx.Repo, {:shared, self()})

    [p1, p2, p3, p4, p5, p6] =
      for _ <- 1..6 do
        insert_user()
      end

    {:ok, %{p1: p1, p2: p2, p3: p3, p4: p4, p5: p5, p6: p6}}
  end

  describe "join/3" do
    test "lets players join and places them in a seat", %{p1: p1} do
      name = p1.name
      assert {:ok, engine} = Engine.join(Engine.new(), p1, 200)
      assert p1.name in engine.seating.arrangement
      refute p1.name in engine.seating.active
      assert %{^name => 200} = engine.chips.chip_roll
    end

    test "returns an error when player joins with fewer than 100 chips", %{p1: p1} do
      engine = Engine.new()
      assert {:error, :join_amount_insufficient} = Engine.join(engine, p1, 95)
      assert {:error, :join_amount_insufficient} = Engine.join(engine, p1, 0)
      assert {:error, :join_amount_insufficient} = Engine.join(engine, p1, -5)
    end

    test "returns an error if max number of players have already joined", context do
      players = [context.p1, context.p2, context.p3, context.p4, context.p5, context.p6]

      {:ok, full_engine} = Enum.reduce(players, Engine.new(), &join(&1, &2))

      assert {:error, :room_full} = Engine.join(full_engine, insert_user(), 200)
    end
  end

  test "returns an error if the player has already joined", context do
    {:ok, engine} = Engine.join(Engine.new(), context.p1, 200)

    assert {:error, :already_joined} = Engine.join(engine, context.p1, 200)
  end

  defp join(player, {:ok, engine}), do: Engine.join(engine, player, 200)
  defp join(player, engine), do: Engine.join(engine, player, 200)
end
