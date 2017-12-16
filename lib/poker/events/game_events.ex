defmodule PokerEx.GameEvents do
  alias PokerExWeb.Endpoint
  alias PokerEx.Player
  import Ecto.Query

  def game_started(room_id, room) do
    map =
      room
      |> game_map()
      |> Map.merge(%{table: []})
      |> Map.merge(%{state: :pre_flop})

    {Endpoint.broadcast!("rooms:" <> room_id, "game_started", map), map}
  end

  def state_updated(room_id, update) do
    map =
      update
      |> game_map()
    Endpoint.broadcast!("rooms:" <> room_id, "update", map)
  end

  def clear(room_id, update) do
    json =
      %{active: nil,
        current_big_blind: nil,
        current_small_blind: nil,
        state: :idle,
        players: [],
        paid: %{},
        round: %{},
        to_call: 0,
        type: Atom.to_string(update.type),
        chip_roll: update.chip_roll,
        pot: update.pot,
        seating: Phoenix.View.render_many(update.seating, PokerExWeb.RoomView, "seating.json", as: :seating),
        player_hands: [],
        table: []
       }
    Endpoint.broadcast!("rooms:" <> room_id, "update", json)
  end

  def game_over(room_id, winner, reward) do
    message = "#{winner} wins #{reward} chips"
    Endpoint.broadcast!("rooms:" <> room_id, "game_finished", %{message: message})
  end

  def winner_message(room_id, message) do
    Endpoint.broadcast!("rooms:" <> room_id, "winner_message", %{message: message})
  end

  def present_winning_hand(room_id, winning_hand, player, type) do
    cards = Enum.map(winning_hand, fn card -> Map.from_struct(card) end)
    Endpoint.broadcast!("rooms:" <> room_id, "present_winning_hand", %{cards: cards, winner: player, type: type})
  end

  defp game_map(room) do
    {active, _} = hd(room.active)
    players =
      if room.active == [] do
        []
      else
        Enum.map(room.active, fn {name, _} -> PokerEx.Repo.one(from p in Player, where: p.name == ^name) end)
      end
    players = Enum.map(players, fn p -> %{chips: p.chips, name: p.name} end)

    base_map =
      %{active: active,
        current_big_blind: room.current_big_blind || nil,
        current_small_blind: room.current_small_blind || nil,
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
    base_map
    |> Map.merge(seating)
    |> Map.merge(player_hands)
  end
end