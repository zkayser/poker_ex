{:ok, _} = Application.ensure_all_started(:hound)

ExUnit.start(capture_log: false)

# Ecto.Adapters.SQL.Sandbox.mode(PokerEx.Repo, :manual)