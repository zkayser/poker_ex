defmodule PokerEx.Repo.Migrations.AddStateToPrivateRoom do
  use Ecto.Migration

  def change do
    alter table(:private_rooms) do
      add :state, :string
    end
  end
end
