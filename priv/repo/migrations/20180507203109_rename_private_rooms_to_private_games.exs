defmodule PokerEx.Repo.Migrations.RenamePrivateRoomsToPrivateGames do
  use Ecto.Migration

  def change do
    rename(table(:private_rooms), to: table(:private_games))
  end
end
