defmodule PokerEx.IntegrationCase do
  use ExUnit.CaseTemplate
  
  using do
    quote do
      use Wallaby.DSL
      
      alias PokerEx.Repo
      import Ecto
      import Ecto.Query
      import Ecto.Changeset
      
      import PokerEx.Router.Helpers
      import PokerEx.TestHelpers
    end
  end
  
  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(PokerEx.Repo)
    
    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(PokerEx.Repo, {:shared, self()})
    end
    
    metadata = Phoenix.Ecto.SQL.Sandbox.metadata_for(PokerEx.Repo, self())
    {:ok, session} = Wallaby.start_session(metadata: metadata)
    {:ok, session: session}
  end
end