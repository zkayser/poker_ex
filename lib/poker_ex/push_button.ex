defmodule PokerEx.PushButton do

	def start_link do
		:gen_statem.start_link(__MODULE__, [], [])
	end
	
	def push(pid) do
		:gen_statem.call(pid, :push)
	end
	
	def get_count(pid) do
		:gen_statem.call(pid, :get_count)
	end
	
	def stop(pid) do
		:gen_statem.stop(pid)
	end
	
	# Callback functions
	def terminate(_reason, _state, _data) do
		:void
	end
	
	def code_change(_vsn, state, data, _extra) do
		{:ok, state, data}
	end
	
	def init([]) do
		{:ok, :off, 0}
	end
	
	def callback_mode do
		:state_functions
	end
	
	# State functions
	
	def off({:call, from}, :push, data) do
		{:next_state, :on, data + 1, [{:reply, from, :on}]}
	end
	
	def off(event_type, event_content, data) do
		handle_event(event_type, event_content, data)
	end
	
	def on({:call, from}, :push, data) do
		{:next_state, :off, data, [{:reply, from, :off}]}
	end
	
	def on(event_type, event_content, data) do
		handle_event(event_type, event_content, data)
	end

	# Handle events common to all states
	def handle_event({:call, from}, :get_count, data) do
		{:keep_state, data, [{:reply, from, data}]}
	end
	
	def handle_event(_, _, data) do
		{:keep_state, data}
	end
end
