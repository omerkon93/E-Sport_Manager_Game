class_name MatchSimulator
extends RefCounted

## Simulates a match between two teams and returns the results.
## We use a static function so you can call it from anywhere without needing to add it to the scene tree!
static func play_match(player_team: ESportTeam, enemy_team: ESportTeam) -> Dictionary:
	# 1. Get the raw stats
	var player_base_power: float = player_team.get_overall_power()
	var enemy_base_power: float = enemy_team.get_overall_power()
	
	# 2. Add RNG (The "Any Given Sunday" factor)
	# This multiplies their power by a random number between 0.8 (bad day) and 1.2 (playing out of their minds)
	var player_final_score: int = int(player_base_power * randf_range(0.8, 1.2))
	var enemy_final_score: int = int(enemy_base_power * randf_range(0.8, 1.2))
	
	# 3. Determine the winner (Player wins ties for the MVP)
	var is_player_winner: bool = player_final_score >= enemy_final_score
	
	# 4. Calculate Prize Money
	var prize_money: int = 1000 if is_player_winner else 250
	
	# 5. Return a nice data packet so your UI knows exactly what happened
	return {
		"player_won": is_player_winner,
		"player_score": player_final_score,
		"enemy_score": enemy_final_score,
		"prize_money": prize_money
	}
