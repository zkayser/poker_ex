defmodule PokerEx.RoomsSupervisor do
  use Supervisor
  
  @registry PokerEx.RoomRegistry
  
  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end
  
  def find_or_create_process(room_id) when is_binary(room_id) or is_atom(room_id) do
    if room_process_exists?(room_id) do
      {:ok, room_id}
    else
      room_id |> create_room_process
    end
  end
  
  def room_process_exists?(room_id) do
    case Registry.lookup(@registry, Atom.to_string(room_id)) do
      [] -> false
      _ -> true
    end
  end
  
  def create_room_process(room_id) when is_binary(room_id) or is_atom(room_id) do
    case Supervisor.start_child(__MODULE__, [room_id]) do
      {:ok, pid} -> 
        Registry.register(@registry, Atom.to_string(room_id), pid)
        {:ok, room_id}
      {:error, {:already_started, _pid}} -> {:error, :room_already_started}
      other -> {:error, other}
    end
  end
  
  def room_process_count, do: Supervisor.which_children(__MODULE__) |> length()
  
  def room_ids do
    Supervisor.which_children(__MODULE__)
    |> Enum.map(
      fn {_, room_proc_pid, _, _} -> 
        Registry.keys(@registry, room_proc_pid)
        |> List.first
      end)
    |> Enum.sort
  end
  
  def init([]) do
    children = [
      worker(PokerEx.Room, [], restart: :transient)
    ]
    
    supervise(children, strategy: :simple_one_for_one)
  end
end