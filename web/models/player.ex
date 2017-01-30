defmodule PokerEx.Player do
	
	use PokerEx.Web, :model
	
	schema "players" do
		field :name, :string
		field :real_name, :string
		field :email, :string
		field :chips, :integer
		field :password, :string, virtual: true
		field :password_hash, :string
		
		timestamps
	end
	
	alias PokerEx.Player
	alias PokerEx.AppState
	alias PokerEx.Events
	
	@type t :: %Player{name: String.t, chips: non_neg_integer}
	
	# defstruct name: nil, chips: nil
	
	@spec new(String.t, pos_integer) :: Player.t
	def new(name, chips \\ 1000) do
		%Player{name: name, chips: chips}
	end
	
	@spec bet(String.t, non_neg_integer, atom()) :: Player.t | {:insufficient_chips, non_neg_integer}
	def bet(name, amount, room_id \\ nil) do
		player = case AppState.get(name) do
			%Player{name: name, chips: chips} -> %Player{name: name, chips: chips}
			_ -> :player_not_found
		end
		
		case player.chips > amount do
			true -> 
				Events.chip_update(room_id, player, player.chips - amount)
				Events.pot_update(room_id, amount)
				%Player{player | chips: player.chips - amount} |> update
			_ -> 
				total = player.chips
				Events.chip_update(room_id, player, 0)
				Events.pot_update(room_id, total)
				%Player{player | chips: 0} |> update
				{:insufficient_chips, total}
		end
	end
	
	@spec reward(String.t, non_neg_integer, atom()) :: Player.t
	def reward(name, amount, room_id) do
		player = case AppState.get(name) do
			%Player{name: name, chips: chips} -> %Player{name: name, chips: chips}
			_ -> :player_not_found
		end
		
		Events.chip_update(room_id, player, player.chips + amount)
		%Player{ player | chips: player.chips + amount} |> update
	end
	
	def update(player) do
		AppState.get_and_update(player)
	end
	
	def changeset(model, params \\ :empty) do
		model
		|> cast(params, ~w(name real_name), [])
		|> validate_length(:name, min: 1, max: 20)
		|> unique_constraint(:name)
	end
	
	def registration_changeset(model, params) do
		model
		|> changeset(params)
		|> cast(params, ~w(password), [])
		|> validate_length(:password, min: 6, max: 100)
		|> put_pass_hash()
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