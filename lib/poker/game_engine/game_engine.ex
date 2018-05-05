defmodule PokerEx.GameEngine do
  use GenServer
  defdelegate name_for(id), to: PokerEx.GameEngine.GamesSupervisor
  defdelegate init(args), to: PokerEx.GameEngine.Server

  def start_link(args) when is_list(args) do
    GenServer.start_link(__MODULE__, args, name: name_for(List.first(args)))
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, [args], name: name_for("#{args}"))
  end

  def join(game_id, player, chip_amount) do
    call_gen_server(game_id, {:join, player.name, chip_amount})
  end

  def call(game_id, player) do
    call_gen_server(game_id, {:call, player.name})
  end

  def check(game_id, player) do
    call_gen_server(game_id, {:check, player.name})
  end

  def raise(game_id, player, amount) do
    call_gen_server(game_id, {:raise, player.name, amount})
  end

  def fold(game_id, player) do
    call_gen_server(game_id, {:fold, player.name})
  end

  def leave(game_id, player) do
    call_gen_server(game_id, {:leave, player.name})
  end

  def player_count(game_id) do
    call_gen_server(game_id, :player_count)
  end

  def player_list(game_id) do
    call_gen_server(game_id, :player_list)
  end

  def state(game_id) do
    call_gen_server(game_id, :state)
  end

  def add_chips(game_id, player, amount) when amount > 0 do
    call_gen_server(game_id, {:add_chips, player.name, amount})
  end

  # This is effectively a no-op for when `add_chips` is called with a negative amount
  def add_chips(game_id, _player, _amount) do
    call_gen_server(game_id, :state)
  end

  def put_state(game_id, new_state, new_data) do
    call_gen_server(game_id, {:put_state, new_state, new_data})
  end

  defp call_gen_server(id, call_params) when is_binary(id) do
    GenServer.call(name_for(id), call_params)
  end
end
