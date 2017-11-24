defmodule PokerEx.Player do
	use PokerExWeb, :model

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
		field :facebook_id, :string
		field :jwt, :string, virtual: true
		has_many :invitations,  PokerEx.Invitation, foreign_key: :sender_id
		has_many :owned_rooms, PokerEx.PrivateRoom, foreign_key: :owner_id
		has_many :received_invitations, PokerEx.Invitation, foreign_key: :recipient_id
		many_to_many :participating_rooms, PokerEx.PrivateRoom, join_through: "participants_private_rooms", join_keys: [participant_id: :id, private_room_id: :id], on_replace: :delete
		many_to_many :invited_rooms, PokerEx.PrivateRoom, join_through: "invitees_private_rooms", join_keys: [invitee_id: :id, private_room_id: :id], on_replace: :delete

		timestamps()
	end

	alias PokerEx.Player
	alias PokerEx.Repo

	@type t :: %Player{name: String.t, chips: non_neg_integer, first_name: String.t | nil,
										 last_name: String.t | nil, email: String.t, password_hash: String.t
										}

	@spec all() :: list(Player.t)
	def all, do: Repo.all(Player)
	
	@spec by_name(String.t) :: Player.t | {:error, :player_not_found}
	def by_name(name) do
		case Repo.get_by(Player, name: name) do
			%Player{} = player -> player
			_ -> {:error, :player_not_found}
		end
	end

	@spec chips(String.t) :: %{chips: non_neg_integer} | {:error, :player_not_found}
	def chips(player_name) do
		case "players" |> where([p], p.name == ^player_name) |> select([:chips]) |> Repo.one() do
			nil -> {:error, :player_not_found}
			res -> res
		end
	end

	@spec reward(String.t, non_neg_integer, atom()) :: Player.t
	def reward(name, amount, _) do

		player = case Repo.one from(p in Player, where: p.name == ^name) do
			nil -> :player_not_found
			player -> player
		end

		changeset = chip_changeset(player, %{"chips" => player.chips + amount})
		case Repo.update(changeset) do
			{:ok, player_struct} ->
				player_struct
			{:error, _} -> {:error, "problem updating chips"}
		end
	end

	def update_chips(username, amount) when amount >= 0 do
		player =
			case Repo.one from(p in Player, where: p.name == ^username) do
				nil -> :player_not_found
				player -> player
			end

		changeset = chip_changeset(player, %{"chips" => player.chips + amount})
		case Repo.update(changeset) do
			{:ok, struct} ->
				{:ok, struct}
			{:error, _} -> {:error, "problem updating chips"}
		end
	end

	def subtract_chips(username, amount) do
		player =
			case Repo.one from(p in Player, where: p.name == ^username) do
				nil -> :player_not_found
				player -> player
			end

		changeset = chip_changeset(player, %{"chips" => player.chips - amount})
		case Repo.update(changeset) do
			{:ok, struct} -> {:ok, struct}
			{:error, _} -> {:error, "problem updating chips"}
		end
	end

	def preload(%Player{} = player) do
		player
		|> Repo.preload([:participating_rooms, :invited_rooms, :owned_rooms])
	end

	def changeset(model, params \\ %{}) do
		model
		|> cast(params, ~w(name first_name last_name email blurb), [])
		|> put_change(:chips, 1000)
		|> validate_length(:name, min: 1, max: 20)
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
		|> validate_required([:name, :email, :password])
		|> put_pass_hash()
	end

	def facebook_reg_changeset(model, params) do
		model
		|> changeset(params)
		|> cast(params, ~w(facebook_id), [])
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
