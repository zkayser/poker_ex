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

	@valid_email ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/
	@default_chips 1000
	@type t :: %Player{name: String.t, chips: non_neg_integer, first_name: String.t | nil,
										 last_name: String.t | nil, email: String.t, password_hash: String.t
										}

	@spec all() :: list(Player.t)
	def all, do: Repo.all(Player)

	@spec get(pos_integer()) :: Player.t | {:error, :player_not_found}
	def get(id) when is_number(id) do
		case Repo.get(Player, id) do
			%Player{} = player -> player
			_ -> {:error, :player_not_found}
		end
	end

	@spec by_name(String.t) :: Player.t | {:error, :player_not_found}
	def by_name(name) do
		case Repo.get_by(Player, name: name) do
			%Player{} = player -> player
			_ -> {:error, :player_not_found}
		end
	end

	@spec delete(Player.t) :: :ok | :error
	def delete(%Player{} = player) do
		case Repo.delete(player) do
			{:ok, _} -> :ok
			{:error, _} -> :error
		end
	end

	@spec chips(String.t) :: non_neg_integer | {:error, :player_not_found}
	def chips(player_name) do
		case "players" |> where([p], p.name == ^player_name) |> select([:chips]) |> Repo.one() do
			nil -> {:error, :player_not_found}
			res -> res.chips
		end
	end

	@spec player_names() :: list(String.t)
	def player_names do
		all()
		|> Stream.map(&(&1.name))
		|> Enum.to_list()
	end

	@spec paginate(list(page_num: pos_integer)) :: Scrivener.Config.t
	def paginate([page_num: page_num]) when is_number(page_num) do
		Player
		|> select([p], p.name)
		|> Repo.paginate(page: page_num)
	end

	@spec search(String.t) :: list(Player.t)
	def search(query_string) when is_binary(query_string) do
		query_string = "%#{query_string}%"
		query = from p in Player,
						where: ilike(p.name, ^query_string),
						select: p.name
		Repo.all(query)
	end

	@spec fb_login_or_create(%{id: String.t, name: String.t}) :: Player.t
	def fb_login_or_create(%{facebook_id: id, name: name}) do
		case Repo.get_by(Player, facebook_id: id) do
			%Player{} = player ->	player
			nil -> Player.create_oauth_user(%{name: name, provider_data: [facebook_id: id]})
		end
	end

	@spec create_oauth_user(%{name: String.t, provider_data: list()}) :: Player.t | :error
	def create_oauth_user(%{name: name, provider_data: provider_data}) do
		name = with %Player{} = player <- by_name(name) do
		 player.name
	 else
	 	_ -> assign_name(name)
	 end
		case provider_data do
			[facebook_id: id] ->
				Repo.insert(
					%Player{name: name,
						 			blurb: "",
						 			chips: @default_chips,
						 			facebook_id: id})
		end
		|> case do
			{:ok, player} -> player
			_ -> :error
		end
	end

	# A hack to enforce unique user names across the app.
	# Appends number 1 to a user's name if that name is already taken.
	# If that already exists, it adds one and cycles through until it finds
	# a name that hasn't been taken.
	@spec assign_name(String.t) :: String.t
	def assign_name(name) when is_binary(name) do
		case Regex.named_captures(~r/(?<digits>\d+$)/, name) do
			%{digits: number} -> name_candidate = "#{name} #{String.to_integer(number) + 1}"
				case by_name(name_candidate) do
					nil -> name_candidate
				 	_ -> assign_name(name_candidate)
				end
			_ ->
				if by_name("#{name} #{1}") != nil, do: "#{name} #{1}", else: assign_name("#{name} #{1}")
		end
	end

	# TODO: 11/26/2017 -- Just revisiting this and
	# am unsure of what exactly the intent of this is.
	# The only calls to this function are in the RewardManager module,
	# but it seems to be weird that the rewards from winning a hand are being added to the
	# Player record in the database here and not just added to the `chip_roll`
	# map managed by Room instances. The reason this is weird is because
	# when a player leaves a room, the amount of chips that player has
	# outstanding (still in play) in the room are removed and added back
	# to the `Player` record in the database. This would seem to be rewarding
	# the player twice, then. Once on the `reward` call, then again when the
	# player leaves the room. This should be fleshed out with an
	# integration test in the `RoomsChannelTest`.
	@spec reward(String.t, non_neg_integer, atom()) :: Player.t
	def reward(name, amount, _room_id) do
		with %Player{} = player <- Repo.one from(p in Player, where: p.name == ^name) do
			changeset = chip_changeset(player, %{"chips" => player.chips + amount})
			case Repo.update(changeset) do
				{:ok, player_struct} ->
					{:ok, player_struct}
				{:error, _} -> {:error, "problem updating chips"}
			end
		else
			_ -> {:error, :player_not_found}
		end
	end

	def update_chips(username, amount) when amount >= 0, do: reward(username, amount, nil)
	def update_chips(_, _), do: {:error, :negative_chip_amount}

	def subtract_chips(username, amount) do
		with %Player{} = player <- Repo.one from(p in Player, where: p.name == ^username) do
			if amount <= player.chips do
				changeset = chip_changeset(player, %{"chips" => player.chips - amount})
				case Repo.update(changeset) do
					{:ok, struct} -> {:ok, struct}
					{:error, _} -> {:error, "problem updating chips"}
				end
			else
				{:ok, player}
			end
		else
			_ -> {:error, :player_not_found}
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
		|> validate_format(:email, @valid_email)
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
