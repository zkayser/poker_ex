defmodule PokerEx.Mixfile do
  use Mix.Project

  def project do
    [
      app: :poker_ex,
      version: "1.2.1",
      elixir: "~> 1.9.0",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {PokerEx.Application, []},
      applications: [
        :phoenix,
        :phoenix_pubsub,
        :phoenix_html,
        :ecto_sql,
        :jason,
        :plug_cowboy,
        :cors_plug,
        :guardian,
        :cowboy,
        :logger,
        :gettext,
        :phoenix_ecto,
        :postgrex,
        :comeonin,
        :bamboo,
        :scrivener,
        :scrivener_ecto,
        :scrivener_list,
        :oauth,
        :ueberauth_facebook,
        :httpotion
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.4.0"},
      {:phoenix_pubsub, "~> 1.0"},
      {:ecto_sql, "~> 3.0"},
      {:phoenix_ecto, "~> 4.0"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 2.6"},
      {:phoenix_live_reload, "~> 1.2.0", only: :dev},
      {:gettext, "~> 0.11"},
      {:plug_cowboy, "~> 2.0"},
      {:credo, "~> 1.0.0", only: [:dev, :test], runtime: false},
      {:plug, "~> 1.7"},
      {:ex_doc, "~> 0.12", only: :dev, runtime: false},
      {:cors_plug, "~> 1.2"},
      {:gen_fsm, "~> 0.1.0"},
      {:guardian, "~> 1.2.0"},
      {:comeonin, "~> 2.0"},
      {:bamboo, "~> 0.8"},
      {:bamboo_smtp, "~> 1.4.0"},
      {:scrivener, "~> 2.7.0"},
      {:scrivener_ecto, "~> 2.2.0"},
      {:scrivener_list, "~> 2.0.1"},
      {:hound, "~> 1.0"},
      {:ueberauth, "~> 0.4"},
      {:oauth, github: "tim/erlang-oauth"},
      {:ueberauth_facebook, "~> 0.6"},
      {:httpotion, "~> 3.0.2"},
      {:exvcr, "~> 0.10", only: :test},
      {:jason, "~> 1.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
