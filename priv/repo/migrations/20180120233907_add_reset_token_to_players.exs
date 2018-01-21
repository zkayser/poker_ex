defmodule PokerEx.Repo.Migrations.AddResetTokenToPlayers do
  use Ecto.Migration

  def change do
  	alter table(:players) do
  		add :reset_token, :string
  	end
  end
end
