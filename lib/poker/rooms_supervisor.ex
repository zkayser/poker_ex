defmodule PokerEx.RoomsSupervisor do
  use Supervisor
  
  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end
  
  def init([]) do
    children = 
      for x <- 1..9 do
        [name: "Room#{x}", mfa: {PokerEx.Room, :start_link, []}]
      end
  end
end