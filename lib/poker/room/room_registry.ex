defmodule PokerEx.RoomRegistry do
  
  def start_link do
    Registry.start_link(:unique, PokerEx.RoomRegistry)
  end
end