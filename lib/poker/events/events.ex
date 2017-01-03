defmodule PokerEx.Events do
  alias PokerEx.GameEvents
  alias PokerEx.PlayerEvents
  alias PokerEx.RoomEvents
  alias PokerEx.TableEvents
  
  @name :events

  def start_link do
    case GenEvent.start_link(name: @name) do
      {:ok, _pid} ->
        add(GameEvents, [])
        add(PlayerEvents, [])
        add(RoomEvents, [])
        add(TableEvents, [])
      _ -> :error
    end
  end
  
  #######
  # API #
  #######
  
  def player_joined(player, position) do
    GenEvent.notify(@name, {:player_joined, player, position})
  end
  
  def game_started(active, cards) do
    GenEvent.notify(@name, {:game_started, active, cards})
  end
  
  def advance(player) do
    GenEvent.notify(@name, {:advance, player})
  end
  
  def card_dealt(card) do
    GenEvent.notify(@name, {:card_dealt, card})
  end
  
  def flop_dealt(flop) do
    GenEvent.notify(@name, {:flop_dealt, flop})
  end
  
  def game_over(winner, reward) do
    GenEvent.notify(@name, {:game_over, winner, reward})
  end
  
  def player_left(player) do
    GenEvent.notify(@name, {:player_left, player})
  end
  
  def chip_update(player, amount) do
    GenEvent.notify(@name, {:chip_update, player, amount})
  end
  
  #####################
  # Utility Functions #
  #####################
  
  defp add(mod, args) do
    GenEvent.add_mon_handler(@name, mod, args)
  end
  
  defp delete(mod, args) do
    GenEvent.remove_handler(@name, mod, args)
  end
end