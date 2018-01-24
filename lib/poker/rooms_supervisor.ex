defmodule PokerEx.RoomsSupervisor do
  use Supervisor
  require Logger

  @registry Registry.Rooms
  @invalid_room_id "Rooms must be started with a unique string identifier"

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def find_or_create_process(room_id) when is_binary(room_id) do
    if room_process_exists?(room_id) do
      {:ok, room_id}
    else
      room_id |> create_room_process
    end
  end

  def room_process_exists?(room_id) do
    case Registry.lookup(@registry, room_id) do
      [] -> false
      [{pid, _}] when is_pid(pid) -> Process.alive?(pid)
      _ -> false
    end
  end

  def create_room_process(room_id) when is_binary(room_id) do
    case Supervisor.start_child(__MODULE__, [room_id]) do
      {:ok, pid} ->
        Registry.unregister(@registry, room_id)
        Registry.register(@registry, room_id, pid)
        {:ok, room_id}
      {:error, {:already_started, _pid}} -> {:ok, room_id}
      other -> {:error, other}
    end
  end
  def create_room_process(_), do: raise(@invalid_room_id)

  def create_private_room(room_id) when is_binary(room_id) do
    case Supervisor.start_child(__MODULE__, [[room_id, :private]]) do
      {:ok, pid} ->
        Registry.unregister(@registry, room_id)
        Registry.register(@registry, room_id, pid)
        {:ok, room_id}
      {:error, {:already_started, _pid}} -> {:error, :room_already_started}
      other -> {:error, other}
    end
  end
  def create_private_room(_), do: raise(@invalid_room_id)

  def room_process_count, do: Supervisor.which_children(__MODULE__) |> length()

  def init([]) do
    {:ok, _} = Registry.start_link(keys: :unique, name: @registry)

    children = [
      worker(PokerEx.Room, [], [restart: :transient])
    ]

    Enum.each(PokerEx.PrivateRoom.all(),
      fn room ->
        IO.puts "Now starting #{inspect room.title}"
        Task.start(fn -> PokerEx.PrivateRoom.ensure_started(room.title) end)
      end)

    supervise(children, strategy: :simple_one_for_one)
  end
end