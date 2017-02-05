defmodule PokerEx.PrivateRoom do
  use PokerEx.Web, :model
  
  schema "private_rooms" do
    field :title, :string
    belongs_to :owner, PokerEx.Player
    many_to_many :participants, PokerEx.Player, join_through: "participants_private_rooms", join_keys: [private_room_id: :id, participant_id: :id]
    many_to_many :invitees, PokerEx.Player, join_through: "invitees_private_rooms", join_keys: [private_room_id: :id, invitee_id: :id]
    timestamps()
  end
  
  def changeset(model, params \\ %{}) do
    model
    |> cast(params, ~w(title))
    |> validate_length(:title, min: 1, max: 16)
  end
  
  def create_changeset(model, %{"owner" => owner} = params) do
    model
    |> changeset(params)
    |> cast_assoc(:owner, required: true)
  end
  
  def update_changeset(model, %{"participants" => participants, "invitees" => invitees} = params) do
    model
    |> changeset(params)
    |> cast_assoc(:participants)
    |> cast_assoc(:invitees)
  end
  
  def update_changeset(model, params \\ %{}) do
    model
    |> changeset(params)
    |> do_update_changeset(params)
  end
  
  defp do_update_changeset(changeset, %{"participants" => participants, "invitees" => invitees} = params) do
    cast_assoc(changeset, :participants)
    |> cast_assoc(:invitees)
  end
  defp do_update_changeset(changeset, %{"participants" => participants} = params) do
    cast_assoc(changeset, :participants)
  end
  defp do_update_changeset(changeset, %{"invitees" => invitees} = params) do
    cast_assoc(changeset, :invitees)
  end
  defp do_update_changeset(changeset, %{}), do: changeset
end