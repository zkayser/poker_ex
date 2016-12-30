defmodule PokerEx do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(PokerEx.Repo, []),
      # Start the endpoint when the application starts
      supervisor(PokerEx.Endpoint, []),
      supervisor(PokerEx.Presence, []),
      # Start your own worker by calling: PokerEx.Worker.start_link(arg1, arg2, arg3)
      worker(PokerEx.AppState, []),
      # The Room worker will be moved out to a separate supervision tree
      # later so there can be multiple instances of it running at the same
      # time.
      # worker(PokerEx.Room, []),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PokerEx.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    PokerEx.Endpoint.config_change(changed, removed)
    :ok
  end
end
