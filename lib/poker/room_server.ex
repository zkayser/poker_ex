defmodule PokerEx.RoomServer do
  use GenServer
  
  def start_link(initial_rooms) do
    GenServer.start_link(__MODULE__, initial_rooms, name: __MODULE__)
  end
  
  def init(rooms \\ 1) do
    send(self(), {:start_rooms, rooms})
    {:ok, %{}}
  end
  
  def handle_info({:start_rooms, rooms}, state) do
    IO.puts "Starting up #{rooms} initial rooms..."
    for x <- 0..rooms do
      room = :"room_#{x}"
      Supervisor.start_child(PokerEx.RoomsSupervisor, [room])
    end
    {:noreply, state}
  end
  
  def handle_info(msg, state) do
    IO.puts "RoomServer - Unknown message received: #{inspect(msg)}"
    {:noreply, state}
  end
end