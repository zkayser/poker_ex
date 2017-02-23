defmodule PokerEx.Repo.Migrations.AddRoomStateToPrivateRooms do
  use Ecto.Migration

  def change do
    alter table(:private_rooms) do
      add :room_state, :binary
    end
  end
end
