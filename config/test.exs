use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :poker_ex, PokerEx.Endpoint,
  http: [port: 4001],
  server: true
  
# Set up SQL Sandbox for Wallaby Integration tests
config :poker_ex, :sql_sandbox, true

# Save screenshot on failed Integration tests
config :wallaby, screenshot_on_failure: true

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :poker_ex, PokerEx.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "poker_ex_test",
  hostname: "localhost",
  template: "template0",
  pool: Ecto.Adapters.SQL.Sandbox
