extends Node

@warning_ignore("unused_signal")
signal roster_updated

# This holds the global reference to your team!
var my_team: ESportTeam

func _ready():
	add_to_group("persist")
	
	var base_team = load("res://game_data/entities/teams/my_first_team.tres")
	if base_team:
		my_team = base_team.duplicate(true) 
		
		for i in range(base_team.active_roster.size()):
			if base_team.active_roster[i] != null:
				my_team.active_roster[i].set_meta("original_path", base_team.active_roster[i].resource_path)
	else:
		push_error("GameManager: Could not load the team!")

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
	
	var path_to_save = player.resource_path
	if path_to_save == "" and player.has_meta("original_path"):
		path_to_save = player.get_meta("original_path")
		
	return {
		"path": path_to_save, 
		"aim": player.aim,
		"energy": player.current_energy,
		"focus": player.current_focus
	}

func _deserialize_player(data: Dictionary) -> ESportPlayer:
	if data.is_empty() or not data.has("path") or data["path"] == "": 
		return null
	
	var base_player = load(data["path"]) as ESportPlayer
	if base_player:
		var instanced_player = base_player.duplicate(true)
		
		instanced_player.set_meta("original_path", data["path"])
		
		instanced_player.aim = data.get("aim", instanced_player.aim)
		instanced_player.current_energy = data.get("energy", instanced_player.current_energy)
		instanced_player.current_focus = data.get("focus", instanced_player.current_focus)
		return instanced_player
		
	return null
