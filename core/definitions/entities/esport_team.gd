class_name ESportTeam
extends Resource

signal roster_changed # NEW: The UI will listen to this!

## 🛡️ Team Identity
@export_group("Team Identity")
@export var team_name: String = "New Team"
@export var team_logo: Texture2D 
@export var is_player_owned: bool = false 

## 👥 Roster
@export_group("Roster")
@export var active_roster: Array[ESportPlayer] = [null, null, null, null, null]
@export var bench: Array[ESportPlayer] = []

## 📊 Match-Day Helper Functions
func get_team_aim() -> int:
	var total_aim: int = 0
	for player in active_roster:
		if player != null: 
			total_aim += player.aim
	return total_aim

func get_team_game_sense() -> int:
	var total_sense: int = 0
	for player in active_roster:
		if player != null:
			total_sense += player.game_sense
	return total_sense

func get_team_teamwork() -> int:
	var total_teamwork: int = 0
	for player in active_roster:
		if player != null:
			total_teamwork += player.teamwork
	return total_teamwork

func get_overall_power() -> int:
	return get_team_aim() + get_team_game_sense() + get_team_teamwork()

# --- ROSTER MANAGEMENT ---

func bench_player(player: ESportPlayer) -> void:
	var idx = active_roster.find(player)
	if idx != -1:
		active_roster[idx] = null 
		bench.append(player)
		print(player.alias + " was sent to the bench.")
		roster_changed.emit() # Tell the UI to redraw!

func sub_in_player(player: ESportPlayer) -> bool:
	var empty_idx = active_roster.find(null)
	
	if empty_idx != -1:
		bench.erase(player)
		active_roster[empty_idx] = player
		print(player.alias + " was subbed into the active roster!")
		roster_changed.emit() # Tell the UI to redraw!
		return true
	else:
		print("Cannot sub in: Active roster is full! Bench someone first.")
		return false

func is_match_ready() -> bool:
	if active_roster.size() != 5: return false
	if active_roster.has(null): return false
	return true
