class_name ESportTeam
extends Resource

## 🛡️ Team Identity
@export_group("Team Identity")
@export var team_name: String = "New Team"
@export var team_logo: Texture2D # You can drag and drop a .png here later
@export var is_player_owned: bool = false # Helps the game know if this is YOUR team or an AI team

## 👥 Roster
@export_group("Roster")
# This array holds our custom ESportPlayer resources. 
# For CS:GO, you'll want to keep the active roster capped at 5 in your UI logic.
@export var active_roster: Array[ESportPlayer] = [null, null, null, null, null]

# NEW: A place to put newly hired players or benched teammates!
@export var bench: Array[ESportPlayer] = []

## 📊 Match-Day Helper Functions
# These functions make your Match Simulation incredibly easy to write.
# Instead of looping through players in your match script, you just call my_team.get_team_aim()

func get_team_aim() -> int:
	var total_aim: int = 0
	for player in active_roster:
		if player != null: # Always good to check in case a slot is empty
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

## Calculates a single "Power Score" for the simplest MVP match resolution
func get_overall_power() -> int:
	return get_team_aim() + get_team_game_sense() + get_team_teamwork()

# --- ROSTER MANAGEMENT ---

## Moves an active player to the bench, leaving an empty slot (null) behind
func bench_player(player: ESportPlayer) -> void:
	var idx = active_roster.find(player)
	if idx != -1:
		active_roster[idx] = null # Leave the slot open!
		bench.append(player)
		print(player.alias + " was sent to the bench.")

## Moves a benched player into the first available empty active slot
func sub_in_player(player: ESportPlayer) -> bool:
	var empty_idx = active_roster.find(null)
	
	if empty_idx != -1:
		bench.erase(player)
		active_roster[empty_idx] = player
		print(player.alias + " was subbed into the active roster!")
		return true
	else:
		print("Cannot sub in: Active roster is full! Bench someone first.")
		return false

## Checks if the active roster is completely full and ready for a match
func is_match_ready() -> bool:
	# 1. The array MUST be exactly 5 slots long
	if active_roster.size() != 5:
		return false
		
	# 2. None of those 5 slots can be empty (null)
	if active_roster.has(null):
		return false
		
	# If it survives those checks, the team is ready!
	return true
