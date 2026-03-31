extends Control
class_name ScheduleRow

@onready var day_label: Label = %DayLabel
@onready var matchup_label: Label = %MatchupLabel
@onready var status_label: Label = %StatusLabel

func set_schedule_data(day_num: int, team_a: ESportTeam, team_b: ESportTeam, current_day: int, match_data: Dictionary) -> void:
	# Debug print for every row spawned
	if team_a.team_name == GameManager.my_team.team_name or team_b.team_name == GameManager.my_team.team_name:
		print("🎨 UI Row Rendering Day ", day_num, " | Has home_score key: ", match_data.has("home_score"))

	day_label.text = "Day " + str(day_num)
	matchup_label.text = team_a.team_name + "  vs  " + team_b.team_name
	
	var my_team_name = GameManager.my_team.team_name
	var is_player_match = (team_a.team_name == my_team_name or team_b.team_name == my_team_name)
	var has_scores = match_data.has("home_score") and match_data.has("away_score")

	if has_scores or day_num < current_day:
		if has_scores:
			var s_home = int(match_data["home_score"])
			var s_away = int(match_data["away_score"])
			
			if is_player_match:
				# Figure out which score belongs to the player
				var my_score = s_home if team_a.team_name == my_team_name else s_away
				var op_score = s_away if team_a.team_name == my_team_name else s_home
				
				if my_score > op_score:
					status_label.text = "WIN (%d - %d)" % [my_score, op_score]
					status_label.add_theme_color_override("font_color", Color.GREEN)
				elif my_score < op_score:
					status_label.text = "LOSS (%d - %d)" % [my_score, op_score]
					status_label.add_theme_color_override("font_color", Color.RED)
				else:
					status_label.text = "DRAW (%d - %d)" % [my_score, op_score]
					status_label.add_theme_color_override("font_color", Color.GRAY)
			else:
				# AI vs AI Match
				status_label.text = "%d - %d" % [s_home, s_away]
				status_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
		else:
			# It's a past day but no score found (shouldn't happen with our new save logic)
			status_label.text = "Finished"
			status_label.add_theme_color_override("font_color", Color.DARK_GRAY)
			
		modulate = Color(0.6, 0.6, 0.6, 1.0) # Dim the row
		
	# ==========================================
	# CASE 2: MATCH IS TODAY
	# ==========================================
	elif day_num == current_day:
		status_label.text = "UP NEXT" if is_player_match else "Scheduled"
		status_label.add_theme_color_override("font_color", Color.YELLOW if is_player_match else Color.WHITE)
		modulate = Color(1.0, 1.0, 1.0, 1.0)
		
	# ==========================================
	# CASE 3: MATCH IS FUTURE
	# ==========================================
	else:
		status_label.text = "Upcoming"
		status_label.add_theme_color_override("font_color", Color.DIM_GRAY)
		modulate = Color(0.8, 0.8, 0.8, 1.0)
