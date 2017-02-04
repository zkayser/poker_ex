defmodule PokerEx.Repo.Migrations.CreatePrivateRoomTable do
  use Ecto.Migration

  def change do
    create table(:private_rooms) do
      add :title, :string, null: false
      add :owner_id, references(:players)
      timestamps()
    end
    
    create unique_index(:private_rooms, [:title])
  end
end
