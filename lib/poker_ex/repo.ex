defmodule PokerEx.Repo do
  use Ecto.Repo, otp_app: :poker_ex, adapter: Ecto.Adapters.Postgres
  use Scrivener, page_size: 10
end
