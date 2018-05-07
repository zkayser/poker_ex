defmodule PokerEx.Repo.Migrations.AddStoredGameDataToPrivateGames do
  use Ecto.Migration

  def change do
    alter table(:private_games) do
      add(:stored_game_data, :map)
    end
  end
end
