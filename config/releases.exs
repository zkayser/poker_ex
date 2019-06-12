import Config

config :poker_ex,
  google_id: System.fetch_env!("GOOGLE_CLIENT_ID_POKER_EX")

config :poker_ex, PokerExWeb.Endpoint,
  load_from_system_env: true,
  http: [port: {:system, "PORT"}],
  url: [host: System.get_env("APP_NAME") <> ".gigalixirapp.com", port: 443],
  force_ssl: [rewrite_on: [:x_forwarded_proto]],
  secret_key_base: System.fetch_env!("SECRET_KEY_BASE"),
  server: true,
  check_origin: true

# Ecto Config
config :poker_ex, PokerEx.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: System.get_env("DATABASE_URL"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
  ssl: true

# Note: The domain key here is a placeholder
# since we do not have a domain set up at this
# point in time. The domain also needs to be
# verified by Mailgun before use.
config :poker_ex, PokerEx.Mailer,
  adapter: Bamboo.MailgunAdapter,
  api_key: System.fetch_env!("MAILGUN_API_KEY"),
  domain: "krex.gigalixirapp.com"

# Uberauth config for Facebook
config :ueberauth, Ueberauth.Strategy.Facebook.OAuth,
  client_id: System.fetch_env!("FACEBOOK_APP_ID"),
  client_secret: System.fetch_env!("FACEBOOK_APP_SECRET"),
  redirect_uri: System.fetch_env!("FACEBOOK_REDIRECT_URI")

config :guardian, Guardian, secret_key: System.fetch_env!("SB_SECRET")
