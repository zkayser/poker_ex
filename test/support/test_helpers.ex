defmodule PokerEx.TestHelpers do
  alias PokerEx.Repo
  
  def insert_user(attrs \\ %{}) do
    changes = Dict.merge(%{
      first_name: "User",
      last_name: "Person",
      name: "user#{Base.encode16(:crypto.rand_bytes(8))}",
      email: "email#{Base.encode16(:crypto.rand_bytes(8))}",
      blurb: " ",
      password: "secretpassword"
    }, attrs)
    
    %PokerEx.Player{}
    |> PokerEx.Player.registration_changeset(changes)
    |> Repo.insert!()
  end
end