defmodule PokerEx.PrivateRoom do
  use PokerEx.Web, :model
  alias PokerEx.Player
  alias PokerEx.Repo
  
  schema "private_rooms" do
    field :title, :string
    belongs_to :owner, PokerEx.Player
    many_to_many :participants, 
                  PokerEx.Player, 
                  join_through: "participants_private_rooms",
                  join_keys: [private_room_id: :id, participant_id: :id],
                  on_delete: :delete_all
    many_to_many :invitees, 
                  PokerEx.Player, 
                  join_through: "invitees_private_rooms", 
                  join_keys: [private_room_id: :id, invitee_id: :id],
                  on_replace: :delete
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
  
  def preload(private_room) do
    private_room |> Repo.preload([:invitees, :owner, :participants])
  end
  
  def put_owner(changeset, owner) do
    owner = 
      case Repo.get(Player, String.to_integer(owner)) do
        nil -> add_error(changeset, :owner, "invalid owner")
        player -> 
          changeset
          |> put_assoc(:owner, player)
      end
  end
  
  def put_invitees(changeset, invitees) when is_list(invitees) do
    invitees = 
      Enum.map(invitees, &String.to_integer/1) 
      |> Enum.map(&(Repo.get(Player, &1)))
      |> Enum.reject(&(&1 == nil))
    changeset
    |> put_assoc(:invitees, invitees)
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