defmodule PokerEx.RoomServer do
  use GenServer

  ##################
  # INITIALIZATION #
  ##################

  def start_link(initial_rooms) do
    GenServer.start_link(__MODULE__, initial_rooms, name: __MODULE__)
  end

  def init(rooms \\ 1) do
    send(self(), {:start_rooms, rooms})
    {:ok, %{}}
  end

  ##########
  # CLIENT #
  ##########

  def get_rooms do
    GenServer.call(__MODULE__, :get_rooms)
  end

  #############
  # CALLBACKS #
  #############

  def handle_call(:get_rooms, _from, %{rooms: rooms} = state) do
    {:reply, rooms, state}
  end

  def handle_info({:start_rooms, rooms}, _state) do
    IO.puts "Starting up #{rooms} initial rooms..."
    rooms = for x <- 1..rooms do
      room = "room_#{x}"
      PokerEx.RoomsSupervisor.find_or_create_process(room)
      room
    end
    {:noreply, %{rooms: rooms}}
  end

  def handle_info(msg, state) do
    IO.puts "RoomServer - Unknown message received: #{inspect(msg)}"
    {:noreply, state}
  end
end
