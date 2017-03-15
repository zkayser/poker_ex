defmodule PokerEx.IntegrationCase do
  use ExUnit.CaseTemplate
  
  using do
    quote do
      # use Wallaby.DSL
      use Hound.Helpers
      
      alias PokerEx.Repo
      import Ecto
      import Ecto.Query
      import Ecto.Changeset
      
      import PokerEx.Router.Helpers
      import PokerEx.TestHelpers
    end
  end
  
  setup tags do
   :ok
  end
end