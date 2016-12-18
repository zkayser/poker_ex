defmodule Euclid do

	def euclid(a, b) when b == 0 do
		{1, 0, a}
	end

	def euclid(a, b) do
		IO.puts "\nA: #{inspect(a)} and B: #{inspect(b)}"
		{x, y, d} = euclid(b, rem(a, b))
		IO.puts "\nX: #{inspect(x)}, Y: #{inspect(y)}, and D: #{inspect(d)}\n"
		{y, x - div(a, b) * y, d}
	end
end