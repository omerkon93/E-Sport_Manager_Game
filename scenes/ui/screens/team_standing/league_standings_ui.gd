extends Control
class_name LeagueStandingsUI

@export var standing_row_scene: PackedScene

@onready var standings_list: VBoxContainer = %StandingsList

func _ready() -> void:
	# Listen to the LeagueManager so it auto-updates when a match finishes!
	LeagueManager.standings_updated.connect(_update_board)
	
	# Draw it initially if data already exists
	_update_board()

func _update_board() -> void:
	# 1. Clear out the old rows
	for child in standings_list.get_children():
		child.queue_free()
		
	# 2. Ask the LeagueManager for the correctly sorted teams
	var sorted_teams = LeagueManager.get_sorted_standings()
	
	# 3. Create a new row for each team in order!
	var current_rank = 1
	for team in sorted_teams:
		var row = standing_row_scene.instantiate() as TeamStandingRow
		standings_list.add_child(row)
		
		# Grab this specific team's stat dictionary
		var team_stats = LeagueManager.standings.get(team, {"wins": 0, "losses": 0, "rounds_won": 0, "rounds_lost": 0})
		
		# Pass the data to the row (Rank, Team Resource, Stats Dict)
		row.set_standing_data(current_rank, team, team_stats)
		
		current_rank += 1
