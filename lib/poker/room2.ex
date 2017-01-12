defmodule PokerEx.Room2 do
	alias PokerEx.Player
	alias PokerEx.Events
	alias PokerEx.RewardManager
	alias PokerEx.Deck
	alias PokerEx.Evaluator
	alias PokerEx.Card
	alias PokerEx.Hand
	
	@name :room2
	@big_blind 10
	@small_blind 5
	
	@type chip_tracker :: %{(String.t | PokerEx.Player.t) => non_neg_integer} | %{}
	@type player_tracker :: [String.t | PokerEx.Player.t] | []
	@type seating :: [{String.t, non_neg_integer}] | []
	@type stats :: [{String.t, pos_integer}] | []
	@type seat_number :: 0..6 | nil
	
	@type t :: %__MODULE__{
							to_call: non_neg_integer,
							paid: chip_tracker,
							round: chip_tracker,
							pot: non_neg_integer,
							called: [String.t],
							seating: seating,
							active: seating,
							big_blind: String.t | nil,
							small_blind: String.t | nil,
							length: non_neg_integer | nil,
							current_big_blind: seat_number,
							current_small_blind: seat_number,
							current_player: String.t | Player.t | nil,
							next_player: String.t | Player.t | nil,
							dealer: String.t | Player.t | nil,
							all_in: player_tracker,
							all_in_round: player_tracker,
							player_hands: [{String.t, [Card.t]}] | [],
							table: [Card.t] | [],
							deck: [Card.t] | [],
							stats: stats,
							winner: String.t | Player.t
												}
	
	defstruct to_call: nil,
						paid: %{},
						round: %{},
						pot: 0,
						called: [],
						seating: [],
						active: [],
						big_blind: nil,
						small_blind: nil,
						length: nil,
						current_big_blind: nil,
						current_small_blind: nil,
						current_player: nil,
						next_player: nil,
						dealer: nil,
						all_in: [],
						all_in_round: [],
						player_hands: [],
						table: [],
						deck: [],
						stats: [],
						winner: nil
						
	def start_link do
		:gen_statem.start_link({:local, @name}, __MODULE__, [], [])
	end
	
	##############
	# Client API #
	##############
	
	def join(player) do
		:gen_statem.cast(@name, {:join, player.name})
	end
	
	def call(player) do
		:gen_statem.cast(@name, {:call, player.name})
	end
	
	def check(player) do
		:gen_statem.cast(@name, {:check, player.name})
	end
	
	def raise(player, amount) do
		:gen_statem.cast(@name, {:raise, player.name, amount})
	end
	
	def fold(player) do
		:gen_statem.cast(@name, {:fold, player.name})
	end
	
	def auto_complete do
		:gen_statem.cast(@name, :auto_complete)
	end
	
	def ready(player) do
		:gen_statem.cast(@name, {:ready, player.name})
	end
	
	def leave(player) do
		:gen_statem.cast(@name, {:leave, player.name})
	end
	
	def get_state do
		:gen_statem.cast(@name, :get_state)
	end
	
	def data do
	  :gen_statem.cast(@name, :data)
	end
	
	def seating do
		:gen_statem.cast(@name, :seating)
	end
	
	def active do
		:gen_statem.cast(@name, :active)
	end
	
	def clear do
		:gen_statem.cast(@name, :clear)
	end
	
	######################
	# Callback Functions #
	######################
	
	def terminate(_reason, _state, _data) do
		:void
	end
	
	def code_change(_vsn, state, data, _extra) do
		{:ok, state, data}
	end
	
	def init(_) do
		{:ok, :idle, %__MODULE__{}}
	end
	
	def callback_mode do
		:handle_event_function
	end
	
	###################
	# State Functions #
	###################
	
	def handle_event(:cast, {:join, player}, :idle, state) do
		state = seat_player(player, state)
		case length(state.seating) > 1 do
			true -> 
				new_state = start_round(state)
				{:next_state, :pre_flop, new_state}
			_ -> 
				{:next_state, :idle, state}
		end
	end
	
	
	#####################
	# Utility Functions #
	#####################
	
	defp seat_player(player, %__MODULE__{seating: seating} = state) do
		seat_number = length(seating)
		new_seating = [{player, seat_number} | Enum.reverse(state.seating)] |> Enum.reverse
		Events.player_joined(player, seat_number)
		state = %__MODULE__{ state | seating: new_seating }
	end
	
	defp start_round(%__MODULE__{seating: seating, big_blind: nil, small_blind: nil} = state) do
		[{big_blind, 0}, {small_blind, 1}|_rest] = seating
		%__MODULE__{ state | active: seating, big_blind: big_blind, small_blind: small_blind, current_big_blind: 0, current_small_blind: 1,
									current_player: small_blind, next_player: big_blind}
	end
	
	defp start_round(%__MODULE__{seating: seating} = state) do
		# Remove players who run out of chips
		out_of_chips = PokerEx.AppState.players |> Enum.map(
			fn %PokerEx.Player{name: name, chips: chips} -> 
				if chips == 0, do: name, else: nil
			end)
			
		seating = Enum.reject(seating, fn {player, _} -> player in out_of_chips end)
		
		try do
			[{big_blind, num}, {small_blind, num2}|_rest] = seating
			
			current_player = 
				case Enum.any?(seating, fn {_, seat} -> seat > num2 end) do
					true -> Enum.find(seating, fn {_, seat} ->  seat == num2 + 1 end)
					_ -> Enum.find(seating, fn {_, seat} -> seat == 0 end)
				end
			
			next_player = 
				case current_player do
					{_, 0} -> Enum.find(seating, fn {_, seat} -> seat == 1 end)
					_ -> 
						if Enum.any?(seating, fn {_, seat} -> seat > num2 + 1 end) do
							Enum.find(seating, fn {_, seat} -> seat == num2 + 2 end)
						else
							Enum.find(seating, fn {_, seat} -> seat == 0 end)
						end
				end
			
			%__MODULE__{ state | active: seating, current_player: current_player, next_player: next_player,
					big_blind: big_blind, small_blind: small_blind, current_big_blind: num, current_small_blind: num2,
					seating: seating
				}
		rescue
			_ -> :not_enough_players
		end
	end
	
	
	
end