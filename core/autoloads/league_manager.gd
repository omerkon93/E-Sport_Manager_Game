extends Node

signal standings_updated

const TEAMS_DIRECTORY = "res://game_data/entities/teams/"

var league_teams: Array[ESportTeam] = []
var standings: Dictionary = {}

# The schedule: An array of Weeks. Each Week is an array of Matches (Dictionaries).
var schedule: Array = []
var current_week: int = 1

# ==============================================================================
# 0. AUTO-SCANNER
# ==============================================================================
func initialize_league(player_team: ESportTeam) -> void:
	var enemy_teams: Array[ESportTeam] = []
	
	# 1. Scan the directory for all team files
	_scan_dir_for_teams(TEAMS_DIRECTORY, enemy_teams)
	
	# 2. Filter out the player's team just in case it's saved in the same folder
	var filtered_enemies: Array[ESportTeam] = []
	for team in enemy_teams:
		if team != player_team and team.team_name != player_team.team_name:
			filtered_enemies.append(team)
			
	print("🔍 LeagueManager: Found %d AI teams in folders." % filtered_enemies.size())
	
	# 3. Start the season using the dynamically loaded teams!
	start_new_season(player_team, filtered_enemies)

func _scan_dir_for_teams(path: String, target_array: Array) -> void:
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				if file_name != "." and file_name != "..":
					_scan_dir_for_teams(path + "/" + file_name, target_array)
			else:
				if file_name.ends_with(".tres") or file_name.ends_with(".res"):
					var resource = load(path + "/" + file_name)
					if resource is ESportTeam: 
						target_array.append(resource)
			file_name = dir.get_next()

# ==============================================================================
# 1. LEAGUE SETUP & SCHEDULING
# ==============================================================================
func start_new_season(player_team: ESportTeam, enemy_teams: Array[ESportTeam]) -> void:
	league_teams.clear()
	standings.clear()
	schedule.clear()
	
	league_teams.append(player_team)
	league_teams.append_array(enemy_teams)
	
	for team in league_teams:
		standings[team] = {
			"points": 0,     # NEW: 3 for Win, 1 for Draw
			"wins": 0,
			"draws": 0,      # NEW: Track draws!
			"losses": 0,
			"rounds_won": 0,
			"rounds_lost": 0
		}
		
	_generate_round_robin_schedule()
	current_week = 1
	print("🏆 LeagueManager: New season started with %d teams!" % league_teams.size())
	standings_updated.emit()

func _generate_round_robin_schedule() -> void:
	# Standard "Circle Method" for generating a schedule where everyone plays everyone once
	var n = league_teams.size()
	var teams = league_teams.duplicate()
	var fixed_team = teams.pop_front()
	
	for week in range(n - 1):
		var week_matches = []
		week_matches.append({"home": fixed_team, "away": teams.back()})
		
		for i in range((n / 2) - 1):
			week_matches.append({"home": teams[i], "away": teams[teams.size() - 1 - i]})
			
		schedule.append(week_matches)
		
		# Rotate the array clockwise
		var last_team = teams.pop_back()
		teams.push_front(last_team)

# ==============================================================================
# 2. MATCH RECORDING & POINTS MATH
# ==============================================================================
func record_match_result(team_a: ESportTeam, team_b: ESportTeam, score_a: int, score_b: int) -> void:
	if not standings.has(team_a) or not standings.has(team_b): return
	
	standings[team_a]["rounds_won"] += score_a
	standings[team_a]["rounds_lost"] += score_b
	standings[team_b]["rounds_won"] += score_b
	standings[team_b]["rounds_lost"] += score_a
	
	if score_a > score_b:
		standings[team_a]["wins"] += 1
		standings[team_a]["points"] += 3 # 3 POINTS TO WINNER
		standings[team_b]["losses"] += 1
	elif score_b > score_a:
		standings[team_b]["wins"] += 1
		standings[team_b]["points"] += 3 # 3 POINTS TO WINNER
		standings[team_a]["losses"] += 1
	else:
		# IT'S A DRAW!
		standings[team_a]["draws"] += 1
		standings[team_a]["points"] += 1 # 1 POINT EACH
		standings[team_b]["draws"] += 1
		standings[team_b]["points"] += 1

	standings_updated.emit()

# ==============================================================================
# 3. AI VS AI SIMULATION
# ==============================================================================
func simulate_ai_matches_for_week(player_team: ESportTeam) -> void:
	if current_week - 1 >= schedule.size():
		print("🏆 The season is over!")
		return
		
	var matches_this_week = schedule[current_week - 1]
	
	print("📅 Simulating AI matches for Week ", current_week)
	for match_pair in matches_this_week:
		var t_a = match_pair["home"]
		var t_b = match_pair["away"]
		
		# Skip the player's match because they already played it manually!
		if t_a == player_team or t_b == player_team:
			continue
			
		# Make the AI play each other using your existing fast simulator!
		var results = MatchSimulator.quick_simulate_match(t_a, t_b)
		record_match_result(t_a, t_b, results["score_a"], results["score_b"])
		
	# Move the league forward to the next week
	current_week += 1
	standings_updated.emit()

# ==============================================================================
# 4. SORTING
# ==============================================================================
func get_sorted_standings() -> Array[ESportTeam]:
	var sorted_teams = league_teams.duplicate()
	sorted_teams.sort_custom(func(a: ESportTeam, b: ESportTeam):
		var stats_a = standings[a]
		var stats_b = standings[b]
		
		# Rule 1: Most POINTS wins!
		if stats_a["points"] != stats_b["points"]:
			return stats_a["points"] > stats_b["points"]
			
		# Rule 2: Point tiebreaker -> Round Differential
		var diff_a = stats_a["rounds_won"] - stats_a["rounds_lost"]
		var diff_b = stats_b["rounds_won"] - stats_b["rounds_lost"]
		return diff_a > diff_b
	)
	return sorted_teams
