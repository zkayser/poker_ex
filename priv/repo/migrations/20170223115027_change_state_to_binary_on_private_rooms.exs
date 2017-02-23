defmodule PokerEx.Repo.Migrations.ChangeStateToBinaryOnPrivateRooms do
  use Ecto.Migration

  def change do
    alter table(:private_rooms) do
      remove :state
    end
  end
end
