defmodule PokerEx.Players.Anon do
  @moduledoc """
  Exposes a struct representing an anonymous
  player/user in the system. These players are
  not database-backed and have no passwords,
  email associations, or oauth data tied to
  them.
  """

  defstruct name: nil,
            chips: 1000,
            guest_id: nil

  @type t() :: %__MODULE__{name: String.t(), chips: non_neg_integer(), guest_id: String.t()}

  def new(%{"name" => name}) do
    {:ok, %__MODULE__{
      name: name,
      guest_id: "#{name}_GUEST_#{Base.encode16(:crypto.strong_rand_bytes(8))}"
    }}
  end
end
