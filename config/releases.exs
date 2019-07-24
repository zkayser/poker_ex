import Config

config :poker_ex,
  google_id: System.fetch_env!("GOOGLE_CLIENT_ID_POKER_EX")

config :poker_ex, PokerExWeb.Endpoint,
  load_from_system_env: true,
  http: [port: {:system, "PORT"}],
  url: [host: System.fetch_env!("POKER_EX_DOMAIN"), port: 443],
  code_reloader: false,
  force_ssl: [rewrite_on: [:x_forwarded_proto]],
  secret_key_base: System.fetch_env!("SECRET_KEY_BASE"),
  server: true,
  check_origin: true

# Ecto Config
config :poker_ex, PokerEx.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: System.get_env("POKER_EX_PROD_USER"),
  password: System.get_env("POKER_EX_PROD_PASSWORD"),
  database: "poker_ex_prod",
  hostname: System.get_env("POKER_EX_HOSTNAME"),
  template: "template0",
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "15"),
  ssl: false

# Note: The domain key here is a placeholder
# since we do not have a domain set up at this
# point in time. The domain also needs to be
# verified by Mailgun before use.
config :poker_ex, PokerEx.Mailer,
  adapter: Bamboo.MailgunAdapter,
  api_key: System.fetch_env!("MAILGUN_API_KEY"),
  domain: System.fetch_env!("POKER_EX_DOMAIN")

# Uberauth config for Facebook
config :ueberauth, Ueberauth.Strategy.Facebook.OAuth,
  client_id: System.fetch_env!("FACEBOOK_APP_ID"),
  client_secret: System.fetch_env!("FACEBOOK_APP_SECRET"),
  redirect_uri: System.fetch_env!("FACEBOOK_REDIRECT_URI")

config :guardian, Guardian, secret_key: System.fetch_env!("SB_SECRET")
