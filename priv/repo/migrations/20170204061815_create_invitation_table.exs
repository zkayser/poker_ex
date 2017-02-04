defmodule PokerEx.Repo.Migrations.CreateInvitationTable do
  use Ecto.Migration

  def change do
    create table(:invitations) do
      add :message, :string
      add :sender_id, references(:players)
      add :recipient_id, references(:players)
      timestamps()
    end
  end
end
