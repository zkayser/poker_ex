defmodule PokerEx.TestHelpers do
  use Hound.Helpers
  alias PokerEx.Repo

  def insert_user(attrs \\ %{}) do
    changes = Map.merge(%{
      first_name: "User",
      last_name: "Person",
      name: "user#{Base.encode16(:crypto.strong_rand_bytes(8))}",
      email: "email#{Base.encode16(:crypto.strong_rand_bytes(8))}",
      blurb: " ",
      password: "secretpassword"
    }, Map.new(attrs))

    %PokerEx.Player{}
    |> PokerEx.Player.registration_changeset(changes)
    |> Repo.insert!()
  end

  def get_text(strategy, selector) do
    find_element(strategy, selector) |> inner_text()
  end

  def build_room(attrs \\ %{}) do
    Map.merge(%PokerEx.Room{}, Map.new(attrs))
  end

  def fake_table_flop do
    [%PokerEx.Card{suit: :hearts, rank: :ace},
     %PokerEx.Card{suit: :diamonds, rank: :two},
     %PokerEx.Card{suit: :spades, rank: :five}
    ]
  end

  def random_string do
    Base.encode16(:crypto.strong_rand_bytes(8))
  end
end
