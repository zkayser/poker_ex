defmodule PokerEx.GameEngine.GamesSupervisor do
  use DynamicSupervisor
  require Logger

  @registry Registry.Games
  @invalid_game_id "Games must be started with a unique string identifier"

  def start_link do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def find_or_create_process(game_id) when is_binary(game_id) do
    if process_exists?(game_id) do
      {:ok, game_id}
    else
      game_id |> create_game_process()
    end
  end

  def process_exists?(id) do
    case Registry.lookup(@registry, id) do
      [] -> false
      [{pid, _}] when is_pid(pid) -> Process.alive?(pid)
      _ -> false
    end
  end

  def get_pid(id) do
    case Registry.lookup(@registry, id) do
      [] -> {:error, :not_started}
      [{pid, _}] when is_pid(pid) -> pid
      _ -> {:error, :pid_not_found}
    end
  end

  def create_game_process(game_id) when is_binary(game_id) do
    case DynamicSupervisor.start_child(__MODULE__, {PokerEx.GameEngine, [game_id]}) do
      {:ok, pid} ->
        Registry.unregister(@registry, game_id)
        Registry.register(@registry, game_id, pid)
        {:ok, game_id}

      {:error, {:already_started, _pid}} ->
        {:ok, game_id}

      other ->
        {:error, other}
    end
  end

  def create_game_process(_), do: raise(@invalid_game_id)

  def create_private_game(game_id) when is_binary(game_id) do
    case DynamicSupervisor.start_child(
           __MODULE__,
           {PokerEx.GameEngine, [[game_id, :private]]}
         ) do
      {:ok, pid} ->
        Registry.unregister(@registry, game_id)
        Registry.register(@registry, game_id, pid)
        {:ok, game_id}

      {:error, {:already_started, _pid}} ->
        {:ok, game_id}

      other ->
        {:error, other}
    end
  end

  def create_private_game(_), do: raise(@invalid_game_id)

  def game_count, do: Supervisor.which_children(__MODULE__) |> length()

  def init([]) do
    {:ok, _} = Registry.start_link(keys: :unique, name: @registry)

    Enum.each(PokerEx.PrivateRoom.all(), fn private_game ->
      Logger.debug("Now starting #{inspect(private_game.title)}")
      Task.start(fn -> PokerEx.PrivateRoom.ensure_started(private_game.title) end)
    end)

    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def name_for([game_title, :private]) when is_binary(game_title) do
    {:via, Registry, {@registry, String.replace(game_title, "%20", "_")}}
  end

  def name_for(game_title) when is_binary(game_title) do
    {:via, Registry, {@registry, String.replace(game_title, "%20", "_")}}
  end

  def name_for(name), do: Kernel.raise("Games must be started with a unique string identifier")
end
