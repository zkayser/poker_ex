defmodule PokerEx.GameEngine do
  def join(room_id, player, chip_amount) do
    call_gen_server(room_id, {:join, player.name, chip_amount})
  end

  def call(room_id, player) do
    call_gen_server(room_id, {:call, player.name})
  end

  def check(room_id, player) do
    call_gen_server(room_id, {:check, player.name})
  end

  def raise(room_id, player, amount) do
    call_gen_server(room_id, {:raise, player.name, amount})
  end

  def fold(room_id, player) do
    call_gen_server(room_id, {:fold, player.name})
  end

  def new(room_id) do
    call_gen_server(room_id, :start)
  end

  def leave(room_id, player) do
    call_gen_server(room_id, {:leave, player.name})
  end

  def player_count(room_id) do
    call_gen_server(room_id, :player_count)
  end

  def player_list(room_id) do
    call_gen_server(room_id, :player_list)
  end

  def state(room_id) do
    call_gen_server(room_id, :state)
  end

  def add_chips(room_id, player, amount) when amount > 0 do
    call_gen_server(room_id, {:add_chips, player.name, amount})
  end

  # This is effectively a no-op for when `add_chips` is called with a negative amount
  def add_chips(room_id, _player, _amount) do
    call_gen_server(room_id, :state)
  end

  def put_state(room_id, new_state, new_data) do
    call_gen_server(room_id, {:put_state, new_state, new_data})
  end

  def start_new_round(room_id) do
    call_gen_server(room_id, :start_new_round)
  end

  def which_state(room_id) when is_binary(room_id) do
    call_gen_server(room_id, :which_state)
  end

  defp statemCall(id, call_params) when is_binary(id) do
    GenServer.call(name_for(id), call_params)
  end

  defp name_for(room_title) when is_binary(room_title) do
    {:via, Registry, {Registry.Rooms, String.replace(room_title, "%20", "_")}}
  end

  defp name_for(_), do: Kernel.raise("Rooms must be started with a unique string identifier")
end
