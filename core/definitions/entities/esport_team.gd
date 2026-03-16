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
@export var active_roster: Array[ESportPlayer] = []

# (Optional for MVP, but good for the future)
@export var benched_players: Array[ESportPlayer] = []


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
