defmodule PokerEx.RewardManager do
	alias PokerEx.Player
	alias PokerEx.Events
	alias PokerEx.Room
	
	@type hand_rankings :: [{String.t, pos_integer}]
	@type paid_in :: [{String.t, pos_integer}]
	@type rewards :: [{String.t, pos_integer}]
	
	@spec manage_rewards(Room.t) :: Room.t
	def manage_rewards(%Room{stats: stats, paid: paid} = room) do
		hand_rankings = Enum.sort(stats, fn {_, score1}, {_, score2} -> score1 > score2 end)
		rewards = manage(hand_rankings, paid)
		%Room{ room | rewards: rewards }
	end
	
	@spec manage_rewards(hand_rankings, paid_in) :: rewards
	def manage_rewards(hand_rankings, paid_in) do
		hand_rankings = Enum.sort(hand_rankings, fn {_, score1}, {_, score2} -> score1 > score2 end)
		manage(hand_rankings, paid_in)
	end
	
	@spec distribute_rewards(Room.t) :: Room.t
	def distribute_rewards(%Room{rewards: rewards, chip_roll: chip_roll} = room) do
		reward_map = Enum.reduce(rewards, %{}, fn ({player, reward}, acc) -> Map.put(acc, player, reward) end)
		update = Map.merge(chip_roll, reward_map, fn _key, v1, v2 -> v1 + v2 end)
		Enum.each(rewards, fn {player, amount} -> Events.game_over(room.room_id, player, amount) end)
		%Room{ room | chip_roll: update }
	end
	
	@spec distribute_rewards(rewards, atom()) :: :ok
	def distribute_rewards(rewards, room_id) do
		Enum.each(rewards, 
			fn {player, amount} -> 
				Player.reward(player, amount, room_id)
				Events.game_over(room_id, player, amount)
			end)
	end
	
	# Used to reward player when all others fold
	@spec reward(Player.t, pos_integer, atom()) :: Player.t
	def reward(player, amount, room_id) do
		Player.reward(player, amount, room_id)
	end
	
	defp manage(hand_rankings, paid_in) when length(hand_rankings) > 0 do
		indexed = Enum.with_index(hand_rankings)
		results = Enum.take_while(indexed, 
			fn {{_name, score}, index} ->
				unless index == 0 do
					{{_, score2}, _} = Enum.find(indexed, fn {{_n, _sc}, i} -> i == index - 1 end)
					score == score2
				else
					true
				end
			end)
		winner_rankings = Enum.map(results, fn {{name, score}, _} -> {name, score} end)
		# The entire above can be replaced with the private function below.
		calculate_rewards_per_winner(winner_rankings, paid_in, %{}, hand_rankings)
	end
	
	defp find_winner_rankings(rankings, _paid_in) do
		indexed = Enum.with_index(rankings)
		results = Enum.take_while(indexed, 
			fn {{_name, score}, index} ->
				unless index == 0 do
					{{_, score2}, _} = Enum.find(indexed, fn {{_n, _sc}, i} -> i == index - 1 end)
					score == score2
				else
					true
				end
			end)
		Enum.map(results, fn {{name, score}, _} -> {name, score} end)
	end
	
	defp find_paid_by_winners(winner_rankings, paid_in) do
		Enum.map(winner_rankings, 
			fn {name, _} ->
				{_, paid} = Enum.find(paid_in, fn {n, _} -> name == n end)
				{name, paid}
			end)
	end
	
	defp sort_paid_by_winners(paid) do
		Enum.sort(paid, fn {_, x}, {_, x1} -> x < x1 end)
	end
	
	defp isolate_winners(winner_list), do: Enum.map(winner_list, fn {winner, _} -> winner end)
	
	defp remove_winners(paid_in, winners) do
		Enum.reject(paid_in, fn {player, _} -> player in winners end)
	end
	
	defp partition_above_min_winner(paid_in, min) do
		Enum.split_with(paid_in, fn {_, paid} -> paid <= min end)
	end
	
	defp credit_this_round(below_min_list, num_winners, min) do
		case length(below_min_list) do
			0 -> min
			_ -> 
				list_values = Enum.map(below_min_list, fn {_, credit} -> div(credit, num_winners) end)
				sum = Enum.sum(list_values)
				sum + min
		end
	end
	
	# Needs to return a list of tuples with elements of the form {String.t, pos_integer}
	def calculate_rewards_per_winner(winner_rankings, paid_in, overall_rewards, hand_rankings) do
		winners = isolate_winners(winner_rankings)
	
		winners_paid = 
			winner_rankings
				|> find_paid_by_winners(paid_in)
				|> sort_paid_by_winners
				
		number_winners = length(winner_rankings)
		
		{_, min} = Enum.min_by(winners_paid, fn {_, paid} -> paid end)
		
		{below_min, above_min} =
			paid_in
				|> remove_winners(winners)
				|> partition_above_min_winner(min)
		
		adjust_above_min_to_min = Enum.map(above_min, fn {name, _} -> {name, min} end)
		
		credit_this_round = credit_this_round((below_min ++ adjust_above_min_to_min), number_winners, min)
		# sum below_min and divide by number_winners, credit each winner with min plus this number
		
			overall_rewards = Enum.reduce(winners_paid, overall_rewards, 
				fn {winner, _}, acc -> 
					Map.update(acc, winner, credit_this_round, &(&1 + credit_this_round)) 
				end)
		
		# Get rid of winners where paid == min, keep those above.
		# Eliminate below_min; pass above_min on to next iteration of function, subtracting min from each entry
		# Subtract min from each entry in winners_paid being passed on to next iteration of function
			update_above_min = Enum.map(above_min, fn {name, number} -> {name, number - min} end)
			winners_remaining = Enum.reject(winners_paid, fn {_, paid} -> paid <= min end)
			winners_remaining = 
				case winners_remaining do
					[] -> []
					_ -> Enum.map(winners_remaining, fn {winner, paid} -> {winner, paid - min} end)
				end
		
		# Check if there is leftover money remaining in the update_above_min paid_in list and whether the
		# winners_remaining list is empty. If it is, filter the hand_rankings where the winners are, then
		# send in the filtered list with the update_above_min list
		winners_remaining = 
			case length(winners_remaining) == 0 && length(update_above_min) > 0 do
				true ->
					Enum.reject(hand_rankings, fn {name, _} -> name in winners end)
					|> find_winner_rankings(update_above_min)
					|> find_paid_by_winners(update_above_min)
					|> sort_paid_by_winners
				_ -> winners_remaining
			end
	
			_calculate_rewards_per_winner(winners_remaining, update_above_min, overall_rewards)
	end
	
	def _calculate_rewards_per_winner(_, [], overall_rewards), do: Map.to_list(overall_rewards)
	
	def _calculate_rewards_per_winner([], paid_in, overall_rewards) do
		map = Enum.reduce(paid_in, %{}, fn {name, amount}, acc -> Map.update(acc, name, amount, &(&1 + amount)) end)
		overall_rewards = Map.merge(overall_rewards, map, fn _key, v1, v2 -> v1 + v2 end)
		_calculate_rewards_per_winner([], [], overall_rewards)
	end
	
	def _calculate_rewards_per_winner(winners_remaining, paid_in, overall_rewards) do
		winners = isolate_winners(winners_remaining)
		
		{_, min} = Enum.min_by(winners_remaining, fn {_, paid} -> paid end)
		
		number_winners = length(winners_remaining)
		
		{below_min, above_min} = 
			paid_in
				|> remove_winners(winners)
				|> partition_above_min_winner(min)
				
		adjust_above_min_to_min = Enum.map(above_min, fn {name, _} -> {name, min} end)
			
		credit_this_round = credit_this_round(below_min ++ adjust_above_min_to_min, number_winners, min)
		
		overall_rewards = Enum.reduce(winners_remaining, overall_rewards,
			fn {winner, _}, acc ->
				Map.update(acc, winner, credit_this_round, &(&1 + credit_this_round))
			end)
		
		update_above_min = Enum.map(above_min, fn {name, number} -> {name, number - min} end)
		winners_remaining = Enum.reject(winners_remaining, fn {_, paid} -> paid <= min end)
		winners_remaining = 
			case winners_remaining do
				[] -> []
				_ -> Enum.map(winners_remaining, fn {winner, paid} -> {winner, paid - min} end)
			end
		_calculate_rewards_per_winner(winners_remaining, update_above_min, overall_rewards)
	end
end