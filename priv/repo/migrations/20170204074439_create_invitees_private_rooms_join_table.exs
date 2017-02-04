defmodule PokerEx.Repo.Migrations.CreateInviteesPrivateRoomsJoinTable do
  use Ecto.Migration

  def change do
    create table(:invitees_private_rooms, primary_key: false) do
      add :invitee_id, references(:players)
      add :private_room_id, references(:private_rooms)
    end
  end
end
