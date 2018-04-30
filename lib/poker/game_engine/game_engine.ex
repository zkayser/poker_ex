defmodule PokerEx.GameEngine do
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

  def new(game_id) do
    call_gen_server(game_id, :start)
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

  def start_new_round(game_id) do
    call_gen_server(game_id, :start_new_round)
  end

  def which_state(game_id) when is_binary(game_id) do
    call_gen_server(game_id, :which_state)
  end

  defp call_gen_server(id, call_params) when is_binary(id) do
    GenServer.call(name_for(id), call_params)
  end

  defp name_for(game_title) when is_binary(game_title) do
    {:via, Registry, {Registry.Rooms, String.replace(game_title, "%20", "_")}}
  end

  defp name_for(_), do: Kernel.raise("Rooms must be started with a unique string identifier")
end
