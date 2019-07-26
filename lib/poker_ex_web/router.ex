defmodule PokerExWeb.Router do
  use PokerExWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:put_secure_browser_headers)

    if Mix.env() == :prod do
      plug Plug.SSL, rewrite_on: [:x_forwarded_proto]
    end

    plug(PokerExWeb.Auth, repo: PokerEx.Repo)
  end

  pipeline :csrf do
    plug(:protect_from_forgery)
  end

  pipeline :api do
    plug(:fetch_session)
    plug(:accepts, ["json"])
  end

  pipeline :api_auth do
    plug(Guardian.Plug.VerifyHeader, realm: "Bearer")
    plug(Guardian.Plug.LoadResource)
  end

  pipeline :auth do
    plug PokerEx.Auth.Pipeline
  end

  pipeline :ensure_authenticated do
    plug Guardian.Plug.EnsureAuthenticated
  end

  scope "/auth", PokerExWeb do
    pipe_through([:browser, :csrf])

    get("/:provider", AuthController, :request)
    get("/:provider/callback", AuthController, :callback)
  end

  # if Mix.env == :dev do
  #  forward "/sent_emails", Bamboo.EmailPreviewPlug
  # end
  scope "/", PokerExWeb do
    # Use the default browser stack
    pipe_through([:browser, :csrf])

    get("/", PageController, :index)
    resources("/players", PlayerController, except: [:index, :delete, :edit])
    resources("/sessions", SessionController, only: [:new, :create, :delete])
  end

  scope "/protected", PokerExWeb do
    pipe_through([:browser, :csrf, :authenticate_player])

    resources("/rooms", RoomController, only: [:index, :show])
  end

  scope "/private", PokerExWeb do
    pipe_through([:browser, :csrf, :authenticate_player])

    resources("/invitations", InvitationController, only: [:new, :create])
    resources("/rooms", PrivateRoomController, except: [:index])
  end

  scope "/facebook", PokerExWeb do
    pipe_through(:browser)

    post("/redirect", FacebookController, :fb_redirect)
    get("/redirect", FacebookController, :fb_redirect)
  end

  scope "/api", PokerExWeb do
    pipe_through(:api)

    resources("/sessions", SessionController, only: [:create])
    resources("/registrations", RegistrationController, only: [:create])
    post("/auth", AuthController, :oauth_handler)
    get("/list/:player/:page", PlayerController, :list)
    post("/forgot_password", ForgotPasswordController, :forgot_password)
    post("/reset_password", ResetPasswordController, :reset_password)
  end
end
