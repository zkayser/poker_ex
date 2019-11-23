defmodule PokerEx.Players.Anon do
  @moduledoc """
  Exposes a struct representing an anonymous
  player/user in the system. These players are
  not database-backed and have no passwords,
  email associations, or oauth data tied to
  them.
  """
  @behaviour PokerEx.Players.Player

  defstruct name: nil,
            chips: 1000,
            guest_id: nil

  @type t() :: %__MODULE__{name: String.t(), chips: non_neg_integer(), guest_id: String.t()}

  @spec new(map()) :: {:ok, t()} | {:error, :missing_name}
  def new(%{"name" => name}) do
    {:ok, %__MODULE__{
      name: name,
      guest_id: "#{name}_GUEST_#{Base.encode16(:crypto.strong_rand_bytes(8))}"
    }}
  end

  def new(_), do: {:error, :missing_name}

  @impl true
  @spec bet(t(), pos_integer) :: {:ok, t()} | :error
  def bet(_player, bet) when bet < 0, do: :error
  def bet(%__MODULE__{chips: chips} = player, bet) do
    case bet >= chips do
      true -> {:ok, %__MODULE__{player | chips: 0}}
      false -> {:ok, %__MODULE__{player | chips: chips - bet}}
    end
  end

  @impl true
  def credit(_player, _chips), do: :ok
end
