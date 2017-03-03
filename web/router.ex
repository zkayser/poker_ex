defmodule PokerEx.Router do
  use PokerEx.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug PokerEx.Auth, repo: PokerEx.Repo
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PokerEx do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    resources "/players", PlayerController
    resources "/sessions", SessionController, only: [:new, :create, :delete]
  end
  
  scope "/protected", PokerEx do
    pipe_through [:browser, :authenticate_player]
    
    resources "/rooms", RoomController, only: [:index, :show]
  end
  
  scope "/private", PokerEx do
    pipe_through [:browser, :authenticate_player]
    
    resources "/invitations", InvitationController, only: [:new, :create]
    resources "/rooms", PrivateRoomController, except: [:index]
  end

  # Other scopes may use custom stacks.
   scope "/api", PokerEx do
     pipe_through :api
     
     get "/list/:player/:page", PlayerController, :list
   end
end
