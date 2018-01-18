defmodule PokerExWeb.AuthControllerTest do
	use PokerExWeb.ConnCase, async: true

	setup do
		{:ok, player} = Repo.insert(%PokerEx.Player{name: "some user", id: "1234"})
		conn = build_conn()
		%{conn: conn, player: player}
	end


end