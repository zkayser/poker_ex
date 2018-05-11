defmodule PokerEx.GameEngine.ScoreManager do
  alias PokerEx.{Player, Hand, Evaluator, RewardManager, Events}
  @type stats :: [{String.t(), pos_integer()}] | []
  @type rewards :: [{String.t(), pos_integer()}] | []

  @type t :: %__MODULE__{
          stats: stats,
          rewards: rewards,
          winners: [String.t()] | [Player.t()] | :none,
          winning_hand: Hand.t() | :none,
          game_id: String.t()
        }

  defstruct stats: [],
            rewards: [],
            winners: :none,
            winning_hand: :none,
            game_id: nil

  def new do
    %__MODULE__{}
  end

  @spec manage_score(PokerEx.GameEngine.Impl.t()) :: t()
  def manage_score(%{phase: phase, scoring: scoring}) when phase != :game_over do
    scoring
  end

  def manage_score(%{phase: :game_over, scoring: scoring, cards: cards} = engine) do
    case length(cards.table) < 5 do
      true ->
        case length(engine.player_tracker.all_in) > 0 do
          true ->
            scoring

          false ->
            update_state(%{scoring | game_id: engine.game_id}, [
              {:auto_win, engine.player_tracker.active},
              {:set_rewards, engine.chips},
              :set_winners
            ])
        end

      false ->
        update_state(%{scoring | game_id: engine.game_id}, [
          {:evaluate_hands, cards},
          {:set_rewards, engine.chips},
          :set_winners,
          {:set_winning_hand, cards}
        ])
    end
  end

  def update_state(scoring, updates) when is_list(updates) do
    Enum.reduce(updates, scoring, &update(&1, &2))
  end

  defp update({:evaluate_hands, cards}, scoring) do
    stats =
      Enum.map(cards.player_hands, &{&1.player, Evaluator.evaluate_hand(&1.hand, cards.table)})
      |> Enum.map(fn {player, hand} -> {player, hand.score} end)

    Map.put(scoring, :stats, stats)
  end

  defp update({:set_rewards, chips}, scoring) do
    Map.put(scoring, :rewards, RewardManager.manage_rewards(scoring.stats, chips.paid))
  end

  defp update(:set_winners, scoring) do
    {_, high_score} = Enum.max_by(scoring.stats, fn {_, score} -> score end)

    winners =
      Enum.filter(scoring.stats, fn {_, score} -> score == high_score end)
      |> Enum.map(fn {player, _} -> player end)

    Enum.each(winners, fn winner ->
      Events.game_over(
        scoring.game_id,
        winner,
        Enum.filter(scoring.rewards, fn {name, _} ->
          winner == name
        end)
        |> hd()
        |> elem(1)
      )
    end)

    %__MODULE__{scoring | winners: winners}
  end

  defp update({:set_winning_hand, cards}, scoring) do
    winning_hand =
      Enum.filter(cards.player_hands, fn data ->
        data.player == hd(scoring.winners)
      end)
      |> hd()

    %__MODULE__{scoring | winning_hand: winning_hand}
  end

  defp update({:auto_win, [player | _]}, scoring) do
    Events.winner_message(scoring.game_id, "#{player} wins the round on a fold")
    Map.put(scoring, :stats, [{player, 1000}])
  end

  #################
  # SERIALIZATION #
  #################

  defimpl Jason.Encoder, for: __MODULE__ do
    alias Jason.Encode

    def encode(value, opts) do
      Encode.map(
        %{
          stats: encode_tuples(value.stats),
          rewards: encode_tuples(value.rewards),
          winners: encode_winners(value.winners),
          winning_hand: encode_winning_hand(value.winning_hand),
          game_id: value.game_id
        },
        opts
      )
    end

    defp encode_tuples(list_tuples) do
      for {key, value} <- list_tuples, do: %{key => value}
    end

    defp encode_winners(:none), do: "none"
    defp encode_winners(list), do: list
    defp encode_winning_hand(:none), do: "none"
    defp encode_winning_hand(hand), do: hand
  end

  @doc """
  Decodes JSON values into ScoreManager structs
  """
  @spec decode(String.t()) :: {:ok, t} | {:error, :decode_failed}
  def decode(%{} = map), do: decode_from_map(map)

  def decode(json) do
    with {:ok, value} <- Jason.decode(json) do
      decode_from_map(value)
    else
      _ ->
        {:error, :decode_failed}
    end
  end

  defp decode_from_map(value) do
    with {:ok, winning_hand_json} <- Jason.encode(value["winning_hand"]),
         {:ok, winning_hand} <- Hand.decode(winning_hand_json) do
      {:ok,
       %__MODULE__{
         stats: decode_to_tuples(value["stats"]),
         rewards: decode_to_tuples(value["rewards"]),
         game_id: value["game_id"],
         winning_hand: winning_hand,
         winners: value["winners"]
       }}
    else
      _ ->
        {:error, :decode_failed}
    end
  end

  defp decode_to_tuples(nil), do: nil

  defp decode_to_tuples(list_maps) do
    Enum.reduce(list_maps, [], fn map, acc ->
      key = Map.keys(map) |> hd()
      [{key, map[key]} | acc]
    end)
    |> Enum.reverse()
  end
end
