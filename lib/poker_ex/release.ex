defmodule PokerEx.Release do
  @app :poker_ex

  def create do
    Application.ensure_started(:ssl)

    for repo <- repos() do
      case repo.__adapter__.storage_up(repo.config) do
        :ok ->
          IO.puts("The database for #{inspect(repo, pretty: true)} has been created")

        {:error, :already_up} ->
          IO.puts("The database for #{inspect(repo)} has already been created.")

        {:error, term} when is_binary(term) ->
          IO.puts("The database for #{inspect(repo)} could not be created: #{term}")

        {:error, term} ->
          IO.puts("The database for #{inspect(repo)} could not be created: #{inspect(term)}")
      end
    end
  end

  def migrate do
    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.load(@app)
    Application.fetch_env!(@app, :ecto_repos)
  end
end
