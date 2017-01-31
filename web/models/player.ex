defmodule PokerEx.Player do
	
	use PokerEx.Web, :model
	
	schema "players" do
		field :name, :string
		field :first_name, :string
		field :last_name, :string
		field :email, :string
		field :chips, :integer
		field :password, :string, virtual: true
		field :password_hash, :string
		
		timestamps
	end
	
	alias PokerEx.Player
	alias PokerEx.AppState
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
		IO.puts "\nIn bet call with params: name - #{inspect(name)}; amount - #{inspect(amount)}; and room_id: #{inspect(room_id)}"
	
		player = case Repo.one from(p in Player, where: p.name == ^name) do
			nil -> :player_not_found
			player -> player
		end
		IO.puts "\nAfter player Repo case with player: #{inspect(player)}"
		
		cond do
			player.chips > amount ->
				changeset = chip_changeset(player, %{"chips" => player.chips - amount})
				IO.puts "\nCond statement happy path with changeset: #{inspect(changeset)}"
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
				changeset = chip_changeset(player, %{"chips" => total})
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
	
	def full_name(%Player{first_name: first, last_name: last}) do
		"#{first} #{last}"
	end
	def full_name(_), do: nil
	
	def changeset(model, params \\ :empty) do
		model
		|> cast(params, ~w(name first_name last_name email), [])
		|> put_change(:chips, 1000)
		|> validate_length(:name, min: 1, max: 20)
		|> unique_constraint(:name)
		|> unique_constraint(:email)
	end
	
	def registration_changeset(model, params) do
		model
		|> changeset(params)
		|> cast(params, ~w(password), [])
		|> validate_length(:password, min: 6, max: 100)
		|> put_pass_hash()
	end
	
	def chip_changeset(model, %{"chips" => chips} = params) do
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
end