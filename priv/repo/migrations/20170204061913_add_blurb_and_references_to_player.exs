defmodule PokerEx.Repo.Migrations.AddBlurbAndReferencesToPlayer do
  use Ecto.Migration

  def change do
    alter table(:players) do
      add :blurb, :string
    end
  end
end
