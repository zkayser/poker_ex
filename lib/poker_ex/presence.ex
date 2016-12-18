defmodule PokerEx.Presence do
	use Phoenix.Presence, otp_app: :poker_ex, pubsub_server: PokerEx.PubSub
end