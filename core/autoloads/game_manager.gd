extends Node

@warning_ignore("unused_signal")
signal roster_updated

# This holds the global reference to your team!
var my_team: ESportTeam

func _ready() -> void:
	# Load your team right when the game starts.
	# ⚠️ IMPORTANT: Update this path to exactly where your team .tres file is located!
	my_team = load("res://game_data/entities/teams/my_first_team.tres")
	
	
	if my_team == null:
		push_error("GameManager: Could not load the team! Check the file path.")

# --- SAVE / LOAD LOGIC ---
func get_save_data() -> Dictionary:
	var active_data = []
	for player in my_team.active_roster:
		active_data.append(_serialize_player(player))
		
	var bench_data = []
	for player in my_team.bench:
		bench_data.append(_serialize_player(player))
		
	return {
		"active": active_data,
		"bench": bench_data
	}

func load_save_data(data: Dictionary) -> void:
	# Rebuild the active roster
	my_team.active_roster.clear()
	for p_data in data.get("active", []):
		my_team.active_roster.append(_deserialize_player(p_data))
		
	# Rebuild the bench
	my_team.bench.clear()
	for p_data in data.get("bench", []):
		my_team.bench.append(_deserialize_player(p_data))

func _serialize_player(player: ESportPlayer) -> Dictionary:
	if player == null: return {}
	return {
		"path": player.resource_path, # We need the file path to load them back!
		"aim": player.aim,
		"energy": player.current_energy,
		"focus": player.current_focus
	}

func _deserialize_player(data: Dictionary) -> ESportPlayer:
	if data.is_empty() or not data.has("path"): return null
	
	# Load the original file
	var player = load(data["path"]) as ESportPlayer
	if player:
		# Apply the saved upgrades and vitals!
		player.aim = data.get("aim", player.aim)
		player.current_energy = data.get("energy", player.current_energy)
		player.current_focus = data.get("focus", player.current_focus)
	return player
