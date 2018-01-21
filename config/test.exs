use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :poker_ex, PokerExWeb.Endpoint,
  http: [port: 4001],
  server: true

# Set up SQL Sandbox for Wallaby Integration tests
config :poker_ex, :sql_sandbox, true

# Save screenshot on failed Integration tests
config :wallaby, screenshot_on_failure: true

# Bamboo emailers
config :poker_ex, PokerEx.Mailer, adapter: Bamboo.TestAdapter

config :poker_ex,
	client_password_reset_endpoint: "http://localhost:8081/#/reset-password"

# Easy # of password hashing rounds on :comeonin
# to speed up tests
config :comeonin, :bcrypt_log_rounds, 4
config :comeonin, :pbkdf2_rounds, 1

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :poker_ex, PokerEx.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: System.get_env("POSTGRES_USER"),
  password: System.get_env("POSTGRES_PASS"),
  database: "poker_ex_test",
  hostname: "localhost",
  template: "template0",
  pool: Ecto.Adapters.SQL.Sandbox
