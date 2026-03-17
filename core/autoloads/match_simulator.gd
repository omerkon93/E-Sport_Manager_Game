extends Node
# Make sure this script is set as an Autoload in Project Settings!

# --- SIGNALS ---
signal match_started(team_a_name: String, team_b_name: String)
signal round_played(round_num: int, winner_name: String, log_text: String, score_a: int, score_b: int)
signal match_finished(final_results: Dictionary)

# --- MATCH SETTINGS ---
const MAX_ROUNDS = 24
const ROUND_DELAY_SECONDS = 1.0

var skip_requested: bool = false

# ==============================================================================
# ASYNC MATCH LOOP
# ==============================================================================
## Call this function from your UI to start the live match!
func play_live_match(team_a: ESportTeam, team_b: ESportTeam) -> void:
	# Reset the flag at the start of every match
	skip_requested = false
	
	match_started.emit(team_a.team_name, team_b.team_name)
	
	var score_a = 0
	var score_b = 0
	
	# 1. Calculate Team Power (MVP Math: Just combining Aim stats)
	var power_a = _calculate_team_power(team_a)
	var power_b = _calculate_team_power(team_b)
	var total_power = power_a + power_b
	
	print("⚔️ MATCH START: ", team_a.team_name, " vs ", team_b.team_name)
	
	# 2. Play the rounds one by one!
	for current_round in range(1, MAX_ROUNDS + 1):
		# Roll a random number to see who wins the round based on their stats
		var roll = randf() * total_power
		var round_winner_name = ""
		var play_by_play = ""
		
		if roll <= power_a:
			score_a += 1
			round_winner_name = team_a.team_name
			play_by_play = _generate_kill_feed(team_a, team_b)
		else:
			score_b += 1
			round_winner_name = team_b.team_name
			play_by_play = _generate_kill_feed(team_b, team_a)
			
		# Broadcast the round result to the UI!
		round_played.emit(current_round, round_winner_name, play_by_play, score_a, score_b)
		print("[Round ", current_round, "] ", play_by_play, " | Score: ", score_a, " - ", score_b)
		
		# Check for a winner (First to 13 wins in a 24 round match!)
		if score_a >= 13 or score_b >= 13:
			break
		
		# If skip is requested, it ignores this and instantly runs the next loop.
		if not skip_requested:
			await get_tree().create_timer(ROUND_DELAY_SECONDS).timeout
		
	## 3. Match is over! Wrap up the results.
	var final_results = {
		"team_a": team_a,
		"team_b": team_b,
		"score_a": score_a,
		"score_b": score_b,
		"winner": team_a if score_a > score_b else team_b,
		"player_won": score_a > score_b #
	}
	
	print("🏆 MATCH OVER! Winner: ", final_results.winner.team_name)
	match_finished.emit(final_results)

# ==============================================================================
# HELPER MATH
# ==============================================================================
func _calculate_team_power(team: ESportTeam) -> float:
	var total_power = 0.0
	for player in team.active_roster:
		if player != null:
			# We can factor in Energy/Focus here later!
			total_power += player.aim 
	return max(total_power, 1.0) # Prevent division by zero

func _generate_kill_feed(winning_team: ESportTeam, losing_team: ESportTeam) -> String:
	# Pick a random player from the winning team to be the MVP of the round
	var killer = winning_team.active_roster.pick_random()
	var victim = losing_team.active_roster.pick_random()
	
	var k_name = killer.alias if killer else "Someone"
	var v_name = victim.alias if victim else "an enemy"
	
	# MVP Flavor text!
	var events = [
		"%s gets a quick entry frag on %s!",
		"%s clutches a 1v2, finishing off %s.",
		"%s holds the angle and drops %s.",
		"A massive tactical play allows %s to flank %s!"
	]
	
	return events.pick_random() % [k_name, v_name]
