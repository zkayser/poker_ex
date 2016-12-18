defmodule CodeLock do
	@name :code_lock
	
	def start_link(code) do
		:gen_statem.start_link({:local, @name}, __MODULE__, code, [])
	end
	
	def button(digit) do
		:gen_statem.cast(@name, {:button, digit})
	end
	
	def init(code) do
		do_lock()
		data = %{code: code, remaining: code}
		{:ok, :locked, data}
	end
	
	def callback_mode do
		:state_functions
	end
	
	def locked(:cast, {:button, digit}, %{code: code, remaining: remaining} = data) do
		case remaining do
			[digit] -> 
				do_unlock()
				{:next_state, :open, %{data | remaining: code}, 10000}
			[digit|rest] ->
				{:next_state, :locked, %{data | remaining: rest}}
			_wrong ->
				{:next_state, :locked, %{data | remaining: code}}
		end
	end
	
	def open(:timeout, _, data) do
		do_lock()
		{:next_state, :locked, data}
	end
	
	def open(:cast, {:button, _}, data) do
		do_lock()
		{:next_state, :locked, data}
	end
	
	defp do_lock do
		IO.puts "Lock"
	end
	
	defp do_unlock do
		IO.puts "Unlock"
	end
	
	def terminate(_reason, state, _data) do
		do_lock()
		:ok
	end
	
	def code_change(_vsn, state, data, _extra) do
		{:ok, state, data}
	end
end