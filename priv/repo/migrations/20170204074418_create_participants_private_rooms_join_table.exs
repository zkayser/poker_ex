defmodule PokerEx.Repo.Migrations.CreateParticipantsPrivateRoomsJoinTable do
  use Ecto.Migration

  def change do
    create table(:participants_private_rooms, primary_key: false) do
      add :participant_id, references(:players)
      add :private_room_id, references(:private_rooms)
    end
  end
end
