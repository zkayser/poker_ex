defmodule PokerEx.Repo.Migrations.AddUniqueConstraintToPrivateGamesTitle do
  use Ecto.Migration

  def change do
    create(unique_index(:private_games, [:title]))
  end
end
