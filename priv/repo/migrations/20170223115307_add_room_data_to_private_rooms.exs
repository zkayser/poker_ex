defmodule PokerEx.Repo.Migrations.AddRoomDataToPrivateRooms do
  use Ecto.Migration

  def change do
    alter table(:private_rooms) do
      add :room_data, :binary
    end
  end
end
