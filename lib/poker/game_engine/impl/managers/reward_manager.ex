defmodule PokerEx.GameEngine.RewardManager do
  alias PokerEx.{Player, Events}

  @type hand_rankings :: [{String.t(), pos_integer}]
  @type paid_in :: [{String.t(), pos_integer}]
  @type rewards :: [{String.t(), pos_integer}]

  @spec manage_rewards(hand_rankings, paid_in) :: rewards
  def manage_rewards(hand_rankings, paid_in) do
    hand_rankings = Enum.sort(hand_rankings, fn {_, score1}, {_, score2} -> score1 > score2 end)
    manage(hand_rankings, Enum.into(paid_in, %{}))
  end

  @spec distribute_rewards(rewards, atom()) :: :ok
  def distribute_rewards(rewards, room_id) do
    Enum.each(rewards, fn {player, amount} ->
      Player.reward(player, amount, room_id)
      Events.game_over(room_id, player, amount)
    end)
  end

  # Used to reward player when all others fold
  @spec reward(Player.t(), pos_integer, atom()) :: Player.t()
  def reward(player, amount, room_id) do
    Player.reward(player, amount, room_id)
  end

  defp manage(rankings, paid_in) do
    grouped_rankings = group_rankings(rankings)
    distribute_rewards_by_group([], grouped_rankings, paid_in)
  end

  defp group_rankings(rankings) do
    Enum.reduce(rankings, %{}, fn {player, ranking}, acc ->
      Map.update(acc, ranking, [player], fn list -> list ++ [player] end)
    end)
  end

  defp distribute_rewards_by_group(acc, %{} = rankings, _) when map_size(rankings) == 0, do: acc

  defp distribute_rewards_by_group(acc, ranking_map, paid_in) do
    paid_in = Enum.into(paid_in, %{})
    highest_ranked = Map.get(ranking_map, Map.keys(ranking_map) |> Enum.max())
    new_highest_ranked = Map.drop(ranking_map, [Map.keys(ranking_map) |> Enum.max()])
    paid_by_highest = Enum.map(highest_ranked, fn player -> {player, paid_in[player]} end)
    {results, new_paid_in} = divy_paid_in(paid_by_highest, paid_in)

    new_eligible_winners =
      case new_highest_ranked do
        %{} = map when map_size(map) == 0 ->
          %{}

        map when is_map(map) ->
          possible_winners =
            Map.get(new_highest_ranked, Map.keys(new_highest_ranked) |> Enum.max())

          Map.update(
            new_highest_ranked,
            Map.keys(new_highest_ranked) |> Enum.max(),
            possible_winners,
            fn list ->
              Enum.reject(list, fn potential_winner ->
                potential_winner not in Map.keys(new_paid_in)
              end)
            end
          )

        _ ->
          :error
      end

    formatted_results = Enum.map(results, fn {player, amount} -> {player, amount} end)

    distribute_rewards_by_group(acc ++ formatted_results, new_eligible_winners, new_paid_in)
  end

  defp divy_paid_in([], _), do: {%{}, %{}}

  defp divy_paid_in(winners_paid, paid_in) do
    winners = Enum.map(winners_paid, fn {player, _amount} -> player end)
    redeem_from = Enum.filter(paid_in, fn {player, _amount} -> player not in winners end)
    {_, minimum_paid_by_winners} = Enum.min_by(winners_paid, fn {_player, amount} -> amount end)
    create_partial_reward_list(%{}, winners_paid, redeem_from, minimum_paid_by_winners)
  end

  defp create_partial_reward_list(acc, %{}, redeem_from, _), do: {acc, redeem_from}
  defp create_partial_reward_list(acc, _, %{} = redeem_from, _), do: {acc, redeem_from}

  defp create_partial_reward_list(_acc, winners_paid, redeem_from, minimum) do
    winners_paid = Enum.into(winners_paid, %{})

    losers_will_pay =
      Enum.reduce(redeem_from, %{}, fn {player, amount}, sub_acc ->
        if amount >= minimum * length(Map.keys(winners_paid)) do
          Map.put(sub_acc, player, minimum * length(Map.keys(winners_paid)))
        else
          Map.put(sub_acc, player, amount)
        end
      end)

    new_redeem_from =
      Enum.map(redeem_from, fn {player, amount} -> {player, amount - losers_will_pay[player]} end)
      |> Enum.into(%{})

    new_redeem_from =
      Enum.reject(new_redeem_from, fn {_player, amount} -> amount <= 0 end) |> Enum.into(%{})

    sum_paid = Enum.sum(Map.values(losers_will_pay))

    added_rewards =
      for {player, _} <- winners_paid do
        {player, div(sum_paid, length(Map.keys(winners_paid)))}
      end

    rewards =
      Enum.reduce(added_rewards, winners_paid, fn {player, amount_earned}, sub_acc ->
        Map.update(sub_acc, player, amount_earned, fn old_amount -> old_amount + amount_earned end)
      end)

    new_winners_paid = Enum.reject(winners_paid, fn {_, amount} -> amount == minimum end)

    new_min =
      if length(new_winners_paid) > 1 do
        Enum.min_by(new_winners_paid, fn {_, amount} -> amount end)
      else
        0
      end

    create_partial_reward_list(rewards, new_winners_paid, new_redeem_from, new_min)
  end
end
