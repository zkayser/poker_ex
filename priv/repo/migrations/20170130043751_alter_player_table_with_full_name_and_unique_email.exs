defmodule PokerEx.Repo.Migrations.AlterPlayerTableWithFullNameAndUniqueEmail do
  use Ecto.Migration

  def change do
    alter table(:players) do
      remove :real_name
      add :first_name, :string
      add :last_name, :string
    end
    
    unique_index(:players, :email)
  end
end
