@tool
extends EditorScript

const PLAYERS_DIR = "res://game_data/entities/players/"
const TEAMS_DIR = "res://game_data/entities/teams/"

func _run() -> void:
	print("🛠️ Starting Bulk Generation (Players & Teams)...")
	
	# Ensure our root team directory exists!
	if not DirAccess.dir_exists_absolute(TEAMS_DIR):
		DirAccess.make_dir_recursive_absolute(TEAMS_DIR)
	
	var player_database = {
		"league_teams/Stranger Ranger": [
			{"alias": "Red Ranger",     "role": 0, "aim": 85, "sense": 80, "teamwork": 95, "cost": 4000},
			{"alias": "Blue Ranger",    "role": 1, "aim": 76, "sense": 90, "teamwork": 88, "cost": 3600},
			{"alias": "Black Ranger",   "role": 2, "aim": 82, "sense": 75, "teamwork": 85, "cost": 3200},
			{"alias": "Yellow Ranger",  "role": 3, "aim": 80, "sense": 72, "teamwork": 90, "cost": 3000},
			{"alias": "Pink Ranger",    "role": 4, "aim": 78, "sense": 84, "teamwork": 92, "cost": 3300}
		],
		"league_teams/The Olympians": [
			{"alias": "Zeus",    "role": 0, "aim": 94, "sense": 88, "teamwork": 60, "cost": 4800},
			{"alias": "Hades",   "role": 1, "aim": 89, "sense": 92, "teamwork": 55, "cost": 4400},
			{"alias": "Apollo",  "role": 2, "aim": 91, "sense": 70, "teamwork": 75, "cost": 3900},
			{"alias": "Athena",  "role": 3, "aim": 78, "sense": 95, "teamwork": 92, "cost": 4100},
			{"alias": "Ares",    "role": 4, "aim": 97, "sense": 50, "teamwork": 40, "cost": 3700}
		]
	}
	
	for category_name in player_database.keys():
		var save_path = PLAYERS_DIR + category_name + "/"
		if not DirAccess.dir_exists_absolute(save_path):
			DirAccess.make_dir_recursive_absolute(save_path)
			
		var generated_players: Array[ESportPlayer] = []
		
		# 1. CREATE THE PLAYERS
		for p_data in player_database[category_name]:
			var new_player = ESportPlayer.new()
			new_player.alias = p_data["alias"]
			new_player.preferred_role = p_data.get("role", 0)
			new_player.aim = p_data.get("aim", 50)
			new_player.game_sense = p_data.get("sense", 50)
			new_player.teamwork = p_data.get("teamwork", 50)
			new_player.hiring_cost = p_data.get("cost", 1000)
			new_player.max_energy = 100.0
			new_player.current_energy = 100.0
			new_player.max_focus = 100.0
			new_player.current_focus = 100.0
			
			var file_name = p_data["alias"].to_lower().replace(" ", "_") + ".tres"
			var full_path = save_path + file_name
			
			ResourceSaver.save(new_player, full_path)
			
			# Load it back from disk so the Team resource references the file, not just memory!
			generated_players.append(load(full_path))
			print("✅ Generated: ", file_name)
			
		# 2. CREATE THE TEAM (Skip if it's the free agents pool)
		if category_name != "free_agents":
			var new_team = ESportTeam.new()
			
			# Format the team name (e.g., "league_teams/neon_syndicate" -> "Neon Syndicate")
			var raw_name = category_name.get_file() 
			new_team.team_name = raw_name.replace("_", " ").capitalize()
			
			# Safely add the 5 players to the team's strictly-typed active roster array
			new_team.active_roster.clear()
			for i in range(5):
				if i < generated_players.size():
					new_team.active_roster.append(generated_players[i])
				else:
					new_team.active_roster.append(null)
				
			# Save the Team resource
			var team_file = raw_name + ".tres"
			var team_path = TEAMS_DIR + team_file
			ResourceSaver.save(new_team, team_path)
			print("🏆 TEAM CREATED: ", new_team.team_name, " -> ", team_path)
			
	print("🎉 Bulk Generation Complete! Check your folders!")
