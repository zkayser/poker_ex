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

      import PokerExWeb.Router.Helpers
      import PokerEx.TestHelpers
    end
  end

  setup _tags do
   :ok
  end
end
