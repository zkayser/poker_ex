import Config

config :poker_ex,
  initial_room_count: 1000,
  initial_game_count: 1000,
  google_certs_module: PokerEx.Auth.Google.Certs,
  deliver_email: true,
  ecto_repos: [PokerEx.Repo]

# Configures the endpoint
config :poker_ex, PokerExWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  render_errors: [view: PokerExWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: PokerEx.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [
    signing_salt: System.get_env("SECRET_KEY_BASE")
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  backends: [:console],
  compile_time_purge_level: :warn

# Use Jason for the JSON parsing library in Phoenix
config :phoenix, :json_library, Jason

# Bamboo adapter configuration now lives in `test.exs`, `dev.exs`, and `prod.exs`
# since the configuration is different for each environment.

# Ueberauth config
config :ueberauth, Ueberauth,
  providers: [
    facebook: {Ueberauth.Strategy.Facebook, [profile_fields: "name,email,first_name,last_name"]}
  ]

config :ueberauth, Ueberauth.Strategy.Facebook.OAuth,
  client_id: System.get_env("FACEBOOK_APP_ID"),
  client_secret: System.get_env("FACEBOOK_APP_SECRET"),
  redirect_uri: System.get_env("FACEBOOK_REDIRECT_URI")

config :guardian, Guardian,
  allowed_algos: ["HS512", "RS256", "SHA256"],
  secret_key: System.get_env("SB_SECRET"),
  issuer: "PokerEx",
  ttl: {30, :days},
  serializer: PokerEx.GuardianSerializer

# Guardian config post upgrade to Guardian 1.2:
config :poker_ex, PokerEx.Auth.Guardian,
  issuer: "poker_ex",
  secret_key: System.get_env("SB_SECRET")

# Configure Hound's webdriver
config :hound, driver: "phantomjs"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
