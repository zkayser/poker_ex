use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :poker_ex, PokerExWeb.Endpoint,
  http: [port: 8080],
  debug_errors: true,
  code_reloader: true,
  check_origin: true,
  watchers: [node: ["node_modules/brunch/bin/brunch", "watch", "--stdin",
                    cd: Path.expand("../assets", __DIR__)]]


# Watch static and templates for browser reloading.
config :poker_ex, PokerExWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{lib/poker_ex_web/views/.*(ex)$},
      ~r{lib/poker_ex_web/templates/.*(eex)$}
    ]
  ]

config :poker_ex, PokerEx.Mailer,
 adapter: Bamboo.MailgunAdapter,
 api_key: System.get_env("MAILGUN_API_KEY"),
 domain:  System.get_env("MAILGUN_SANDBOX_DOMAIN")

config :poker_ex,
  client_password_reset_endpoint: "localhost:8081/#/password_reset"

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Configure your database
config :poker_ex, PokerEx.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: System.get_env("POSTGRES_USER"),
  password: System.get_env("POSTGRES"),
  database: "poker_ex_dev",
  hostname: "localhost",
  template: "template0",
  pool_size: 10
