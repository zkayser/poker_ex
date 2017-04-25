defmodule PokerEx.Repo.Migrations.AddFacebookIdToUsers do
  use Ecto.Migration

  def change do
    alter table(:players) do
      add :facebook_id, :string
    end
  end
end
