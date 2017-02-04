defmodule PokerEx.PrivateRoom do
  use PokerEx.Web, :model
  
  schema "private_rooms" do
    field :title, :string
    belongs_to :owner, PokerEx.Player
    many_to_many :participants, PokerEx.Player, join_through: "participants_private_rooms", join_keys: [private_room_id: :id, participant_id: :id]
    many_to_many :invitees, PokerEx.Player, join_through: "invitees_private_rooms", join_keys: [private_room_id: :id, invitee_id: :id]
  end
end