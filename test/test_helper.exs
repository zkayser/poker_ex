{:ok, _} = Application.ensure_all_started(:hound)

# Application.put_env(:wallaby, :base_url, PokerEx.Endpoint.url)

ExUnit.start()

# Ecto.Adapters.SQL.Sandbox.mode(PokerEx.Repo, :manual)