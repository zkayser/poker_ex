defmodule PokerExWeb.Router do
  use PokerExWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug Phoenix.LiveView.Flash
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
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

  scope "/", PokerExWeb do
    pipe_through :browser

    get "/", HomeController, :index
  end

  # if Mix.env == :dev do
  #  forward "/sent_emails", Bamboo.EmailPreviewPlug
  # end
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
