defmodule PokerEx.MapUtils do
  def to_atom_keys(map) do
    Map.new(map, &atom_map_builder/1)
  end

  def atom_map_builder({key, value}) when is_binary(key) do
    {String.to_atom(key), value}
  end

  def atom_map_builder({key, value}), do: {key, value}
end
