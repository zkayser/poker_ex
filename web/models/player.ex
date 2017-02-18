defmodule PokerEx.Player do
	
	use PokerEx.Web, :model
	
	@derive {Poison.Encoder, only: [:chips, :name]}
	schema "players" do
		field :name, :string
		field :first_name, :string
		field :last_name, :string
		field :email, :string
		field :chips, :integer
		field :password, :string, virtual: true
		field :password_hash, :string
		field :blurb, :string
		has_many :invitations,  PokerEx.Invitation, foreign_key: :sender_id
		has_many :owned_rooms, PokerEx.PrivateRoom, foreign_key: :owner_id
		has_many :received_invitations, PokerEx.Invitation, foreign_key: :recipient_id
		many_to_many :participating_rooms, PokerEx.PrivateRoom, join_through: "participants_private_rooms", join_keys: [participant_id: :id, private_room_id: :id]
		many_to_many :invited_rooms, PokerEx.PrivateRoom, join_through: "invitees_private_rooms", join_keys: [invitee_id: :id, private_room_id: :id]
		
		timestamps()
	end
	
	alias PokerEx.Player
	alias PokerEx.Events
	alias PokerEx.Repo
	
	@type t :: %Player{name: String.t, chips: non_neg_integer, first_name: String.t | nil, 
										 last_name: String.t | nil, email: String.t, password_hash: String.t
										}
	
	# No longer have any use for this function after shifting to Ecto-backed model
	@spec new(String.t, pos_integer) :: Player.t
	def new(name, chips \\ 1000) do
		%Player{name: name, chips: chips}
	end
	
	# This is going to have side effects and should ideally be moved into a different module
	@spec bet(String.t, non_neg_integer, atom()) :: Player.t | {:insufficient_chips, non_neg_integer}
	def bet(name, amount, room_id \\ nil) do
	
		player = case Repo.one from(p in Player, where: p.name == ^name) do
			nil -> :player_not_found
			player -> player
		end
		
		cond do
			player.chips > amount ->
				changeset = chip_changeset(player, %{"chips" => player.chips - amount})
				case Repo.update(changeset) do
					{:ok, player_struct} -> 
						Events.chip_update(room_id, player, player.chips - amount)
						Events.pot_update(room_id, amount)
						player_struct
					{:error, _} ->
						{:error, "could not update chips"}
				end
			true ->
				total = player.chips
				changeset = chip_changeset(player, %{"chips" => 0})
				case Repo.update(changeset) do
					{:ok, _} ->
						Events.chip_update(room_id, player, 0)
						Events.pot_update(room_id, total)
						{:insufficient_chips, total}
				end
		end
	end
	
	# Same as above
	@spec reward(String.t, non_neg_integer, atom()) :: Player.t
	def reward(name, amount, room_id) do
	
		player = case Repo.one from(p in Player, where: p.name == ^name) do
			nil -> :player_not_found
			player -> player
		end
		
		changeset = chip_changeset(player, %{"chips" => player.chips + amount})
		case Repo.update(changeset) do
			{:ok, player_struct} -> 
				Events.chip_update(room_id, player, player.chips + amount)
				player_struct
			{:error, _} -> {:error, "problem updating chips"}
		end
	end
	
	def changeset(model, params \\ :empty) do
		model
		|> cast(params, ~w(name first_name last_name email blurb), [])
		|> put_change(:chips, 1000)
		|> validate_length(:name, min: 1, max: 20)
		|> validate_length(:blurb, min: 10, max: 150)
		|> unique_constraint(:name)
		|> unique_constraint(:email)
	end
	
	def association_changeset(model, params \\ %{}) do
		model
		|> update_changeset(params)
		|> cast_assoc(:owned_rooms)
	end
	
	def registration_changeset(model, params \\ :empty) do
		model
		|> changeset(params)
		|> cast(params, ~w(password), [])
		|> validate_length(:password, min: 6, max: 100)
		|> put_pass_hash()
	end
	
	def update_changeset(model, params \\ %{}) do
		model
		|> cast(params, ~w(name first_name last_name email chips blurb))
		|> validate_chips_update(model.chips)
		|> validate_length(:name, min: 1, max: 20)
		|> unique_constraint(:name)
		|> unique_constraint(:email)
	end
	
	def chip_changeset(model, %{"chips" => _chips} = params) do
		model
		|> cast(params, ~w(chips), [])
	end
	
	defp put_pass_hash(changeset) do
		case changeset do
			%Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
				put_change(changeset, :password_hash, Comeonin.Bcrypt.hashpwsalt(pass))
			_ ->
				changeset
		end
	end
	
	defp validate_chips_update(%Ecto.Changeset{changes: %{chips: _update}} = changeset, chips) when chips >= 100 do
		%Ecto.Changeset{changeset | changes: %{changeset.changes | chips: chips}}
	end
	defp validate_chips_update(changeset, _chips), do: changeset
end