extends Node
"""

## Returns if a matchup is available, and shows an error if not
func is_matchup_available() -> bool:
	@warning_ignore("integer_division")
	var is_available = (player_match_data.keys().size() / 2) < (local_group_data.size() - 2)
	if not is_available:
		toast.toast("No matchups available!", 3.0, {
			"modulate" = Color(1, 0.3, 0.3)
		})
	
	return is_available


func _on_match_two_random_pressed() -> void:
	if not is_matchup_available():
		return
	
	var first_random_file_name = local_group_data.pick_random()
	while first_random_file_name in player_match_data.keys():
		local_group_data.pick_random()
	
	var first_random_data = players.player_data[first_random_file_name]
	var first_year = int(first_random_file_name.split(".")[-1].split("_")[-1])
	
	print("<< ---- ATTEMPTING TO MATCH WITH %s ---- >>" % first_random_file_name)
	
	var leniency = 100
	
	var other_random_file_name
	var found_match = false
	var potential_matches_seen = []
	
	var other_players = local_group_data.duplicate()
	other_players.erase(first_random_file_name)
	for file_name in player_match_data.keys():
		other_players.erase(file_name)
	other_players.shuffle()
	
	var debug_hasnt_seen = {}
	for key in other_players:
		debug_hasnt_seen[key] = players.player_data[key].mmr
	print(other_players)
	
	while not found_match:
		if leniency > 10000:
			print_rich('[b]Forced to terminate because search was failing repeatedly[/b]')
			return
		print("Leniency: ", leniency)
		
		for other_file_name in other_players:
			var other_data = players.player_data[other_file_name]
			
			print("--> Checking if matchup: {other_fn} ({other_mmr}) can match {fn} ({mmr})...".format({
				"other_fn" = other_file_name,
				"other_mmr" = other_data.mmr,
				"fn" = first_random_file_name,
				"mmr" = first_random_data.mmr,
			}))
			
			var mmr_difference = abs(first_random_data.mmr - other_data.mmr)
			if mmr_difference < leniency:
				potential_matches_seen.append(other_file_name)
				debug_hasnt_seen.erase(other_file_name)
				
				var last_played_position = first_random_data.last_played.find(other_file_name)
				last_played_position = last_played_position if last_played_position != -1 else 3000000
				
				var history_probability = last_played_position * (1 / float(LAST_PLAYED_HISTORY_SIZE))
				
				var other_year = int(other_file_name.split(".")[-1].split("_")[-1])
				var difference = abs(first_year - other_year)
				
				var age_probability = 1 - 0.12 * difference
				
				## A quinary out easing from 0.7 - 1
				var mmr_probability = 0.7 + 0.3 * (1 - (1 - mmr_difference / 10_000) ** 5)
				
				print("OK! Random offsets: history: ",
				history_probability, " mmr diff: ", mmr_probability, " age diff: ", age_probability)
				
				if randf() < mmr_probability and randf() < history_probability and randf() < age_probability:
					print("Matched.")
					other_random_file_name = other_file_name
					found_match = true
					break
		
		leniency += 100
		
		print("Seen {0}/{1} potential matches (remaining: {2}, size {3})".format([
			potential_matches_seen.size(), local_group_data.size() - 1,
			str(debug_hasnt_seen), debug_hasnt_seen.size()
		]))
		
		if potential_matches_seen.size() >= local_group_data.size() - 1:
			print("Cleared!")
			potential_matches_seen = []
			local_group_data.shuffle()
			leniency = 100
	
	var other_random_data = players.player_data[other_random_file_name]
	
	first_random_data.last_played.insert(0, other_random_file_name)
	other_random_data.last_played.insert(0, first_random_file_name)
	
	if first_random_data.last_played.size() > 3:
		first_random_data.last_played.remove_at(-1)
	if other_random_data.last_played.size() > 3:
		other_random_data.last_played.remove_at(-1)
	
	var first_file = FileAccess.open(players_path + "/" + first_random_file_name + ".player", FileAccess.WRITE)
	first_file.store_var(first_random_data)
	
	var second_file = FileAccess.open(players_path + "/" + other_random_file_name + ".player", FileAccess.WRITE)
	second_file.store_var(other_random_data)
	
	var first_first_name = first_random_file_name.split(".")[0]
	var other_first_name = other_random_file_name.split(".")[0]
	toast.toast("Matched {0} and {1}!".format([first_first_name, other_first_name]), 4)
	create_match_banner(first_random_file_name, other_random_file_name)


"""
