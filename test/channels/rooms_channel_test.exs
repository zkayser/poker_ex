defmodule PokerEx.RoomChannelTest do
	use PokerExWeb.ChannelCase
	import PokerEx.TestHelpers
	alias PokerExWeb.RoomsChannel
	# alias PokerEx.Player --> Not used yet.
	alias PokerEx.Room

	@endpoint PokerExWeb.Endpoint

	setup do
		{:ok, _} = Room.start_link("room_test")
		
		{socket, player, token, reply} = create_player_and_connect()
		
		{:ok, socket: socket, player: player, token: token, reply: reply}
	end

	test "authentication works", context do
		assert {:player_id, context.player.id} in context.socket.assigns
	end

	test "room join", context do
		for key <- [:join_amount, :player, :type, :room] do
			assert key in Map.keys(context.socket.assigns)
		end

		seated_players = for {player, _pos} <- Room.state(:room_test).seating, do: player
		
		assert context.player.name in seated_players
		assert Room.which_state(:room_test) == :idle
	end
	
	test "second player joins", context do
		{_, player, _, _} = create_player_and_connect()
		
		room_state = Room.state(:room_test)
		
		assert length(room_state.seating) == 2
		assert length(room_state.active) == 2
		
		seated_players = for {player, _} <- room_state.seating, do: player
		
		for player <- [context.player.name, player.name], do: assert player in seated_players
		assert Room.which_state(:room_test) == :pre_flop
	end
	
	defp create_player_and_connect do
		player = insert_user()
		
		token = Phoenix.Token.sign(socket(), "user socket", player.id)
		
		{:ok, socket} = connect(PokerExWeb.UserSocket, %{"token" => token})
		
		{:ok, reply, socket} = subscribe_and_join(socket, RoomsChannel, "rooms:room_test",
																							%{"type" => "public", "amount" => 500})
																							
		{socket, player, token, reply}								
	end
end