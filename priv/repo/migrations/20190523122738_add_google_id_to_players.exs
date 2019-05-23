defmodule PokerEx.Repo.Migrations.AddGoogleIdToPlayers do
  use Ecto.Migration

  def change do
    alter table(:players) do
      add(:google_id, :string)
    end
  end
end
