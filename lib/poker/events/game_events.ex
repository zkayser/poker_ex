defmodule PokerEx.GameEvents do
  alias PokerEx.Endpoint
  alias PokerEx.Player
  import Ecto.Query
  
  def game_started(room_id, room) do
    map =
      room
      |> game_map()
      |> Map.merge(%{table: []})
    Endpoint.broadcast!("players:" <> room_id, "game_started", map)  
  end
  
  def state_updated(room_id, update) do
    map =
      update
      |> game_map()
    Endpoint.broadcast!("players:" <> room_id, "update", map)
  end

  def game_over(room_id, winner, reward) do
    message = "#{winner} wins #{reward} chips"
    Endpoint.broadcast!("players:" <> room_id, "game_finished", %{message: message})
  end
  
  def winner_message(room_id, message) do
    Endpoint.broadcast!("players:" <> room_id, "winner_message", %{message: message})
  end
  
  def present_winning_hand(room_id, winning_hand, player, type) do
    cards = Enum.map(winning_hand, fn card -> Map.from_struct(card) end)
    Endpoint.broadcast!("players:" <> room_id, "present_winning_hand", %{cards: cards, winner: player, type: type})
  end
  
  defp game_map(room) do
    {active, _} = hd(room.active)
    players = 
      if room.active == [] do
        []
      else
        Enum.map(room.active, 
        fn {name, _} -> 
            PokerEx.Repo.one(from p in Player, where: p.name == ^name)
        end)
      end
    players = Enum.map(players, fn p -> %{chips: p.chips, name: p.name} end)
    
    base_map = 
      %{active: active,
        players: players,
        paid: room.paid, 
        round: room.round, 
        to_call: room.to_call,
        type: Atom.to_string(room.type),
        chip_roll: room.chip_roll,
        pot: room.pot}
    seating = %{seating: Enum.map(room.seating, fn {name, pos} -> %{name: name, position: pos} end)}
    player_hands = %{player_hands: 
                     Enum.map(room.player_hands, fn {player, [card1, card2]} -> %{player: player, hand: [Map.from_struct(card1), Map.from_struct(card2)]} end)
                    }
    map =  
      base_map
      |> Map.merge(seating)
      |> Map.merge(player_hands)
  end
end