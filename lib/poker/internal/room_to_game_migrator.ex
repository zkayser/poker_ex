defmodule PokerEx.RoomToGameMigrator do
  alias PokerEx.GameEngine.Impl, as: Game

  alias PokerEx.GameEngine.{
    PlayerTracker,
    Seating,
    RoleManager,
    ChipManager,
    CardManager,
    ScoreManager
  }

  def transform_data(old_data) do
    %Game{
      player_tracker: %PlayerTracker{
        active: convert_active(old_data.active),
        all_in: old_data.all_in,
        called: old_data.called,
        folded: old_data.folded
      },
      chips: %ChipManager{
        chip_roll: old_data.chip_roll,
        paid: old_data.paid,
        round: old_data.round,
        pot: old_data.pot,
        to_call: old_data.to_call
      },
      roles: %RoleManager{
        big_blind: old_data.current_big_blind,
        small_blind: old_data.current_small_blind
      },
      cards: %CardManager{
        table: old_data.table,
        deck: old_data.deck,
        player_hands: convert_player_hands(old_data.player_hands)
      },
      seating: %Seating{arrangement: old_data.seating},
      phase: old_data.phase,
      game_id: old_data.room_id,
      type: old_data.type,
      scoring: %ScoreManager{
        rewards: old_data.rewards,
        stats: old_data.stats,
        game_id: old_data.room_id,
        winners: :none
      }
    }
  end

  defp convert_active(list) do
    Enum.map(list, fn {name, _} -> name end)
  end

  defp convert_player_hands(list) do
    for {name, hand} <- list do
      %{player: name, hand: hand}
    end
  end
end
