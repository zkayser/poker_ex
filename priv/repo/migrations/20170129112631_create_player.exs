defmodule PokerEx.Repo.Migrations.CreatePlayer do
  use Ecto.Migration

  def change do
    create table(:players) do
      add :name, :string, null: false
      add :real_name, :string, null: false
      add :email, :string
      add :password_hash, :string
      
      timestamps()
    end
    
    create unique_index(:players, [:name])
  end
end
