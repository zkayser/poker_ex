defmodule PokerEx.TestData do
  alias PokerEx.GameEngine.Impl, as: Engine
  @join_amount 200

  @doc """
  Takes a context object with a map that contains
  six players (constitutes a full room).
  The context is assumed to contain a map that
  conforms to the following structure:
  %{p1: p1, p2: p2, p3: p3, p4: p4, p5: p5, p6: p6}
  where each value is a PokerEx.Player struct.
  Each player joins the game with 200 chips
  """
  def join_all(context) do
    [context.p1, context.p2, context.p3, context.p4, context.p5, context.p6]
    |> Enum.reduce(Engine.new(), &join/2)
  end

  defp join(player, {:ok, engine}), do: Engine.join(engine, player, @join_amount)
  defp join(player, engine), do: Engine.join(engine, player, @join_amount)
end
