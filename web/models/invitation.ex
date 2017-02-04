defmodule PokerEx.Invitation do
  use PokerEx.Web, :model
  
  schema "invitations" do
    field :message, :string
    belongs_to :sender, PokerEx.Player
    belongs_to :recipient, PokerEx.Player
  end
end