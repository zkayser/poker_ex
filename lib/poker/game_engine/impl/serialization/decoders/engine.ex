defmodule PokerEx.GameEngine.Decoders.Engine do
  alias PokerEx.GameEngine.Impl, as: Game

  alias PokerEx.GameEngine.{
    AsyncManager,
    CardManager,
    ChipManager,
    PlayerTracker,
    RoleManager,
    ScoreManager,
    Seating
  }

  @behaviour PokerEx.GameEngine.Decoder

  def decode(nil), do: nil

  def decode(json) do
    with {:ok, value} <- Jason.decode(json),
         {:ok, async_manager} <- AsyncManager.decode(value["async_manager"]),
         {:ok, cards} <- CardManager.decode(value["cards"]),
         {:ok, chips} <- ChipManager.decode(value["chips"]),
         {:ok, player_tracker} <- PlayerTracker.decode(value["player_tracker"]),
         {:ok, roles} <- RoleManager.decode(value["roles"]),
         {:ok, scoring} <- ScoreManager.decode(value["scoring"]),
         {:ok, seating} <- Seating.decode(value["seating"]) do
      {:ok,
       %Game{
         async_manager: async_manager,
         cards: cards,
         chips: chips,
         game_id: value["game_id"],
         phase: String.to_existing_atom(value["phase"]),
         player_tracker: player_tracker,
         roles: roles,
         scoring: scoring,
         seating: seating,
         timeout: value["timeout"],
         type: String.to_existing_atom(value["type"])
       }}
    else
      error -> error
    end
  end
end
