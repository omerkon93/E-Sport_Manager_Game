extends HBoxContainer
class_name TeamStandingRow

@onready var rank_label: Label = %RankLabel
@onready var name_label: Label = %NameLabel
@onready var wins_label: Label = %WinsLabel
@onready var losses_label: Label = %LossesLabel
@onready var diff_label: Label = %DiffLabel

func set_standing_data(rank: int, team: ESportTeam, stats: Dictionary) -> void:
	rank_label.text = str(rank)
	name_label.text = team.team_name
	wins_label.text = str(stats["wins"])
	losses_label.text = str(stats["losses"])
	
	# If you added a Draws and Points label to the UI:
	# draws_label.text = str(stats["draws"])
	# points_label.text = str(stats["points"])
	
	var diff = stats["rounds_won"] - stats["rounds_lost"]
	
	if diff > 0:
		diff_label.text = "+" + str(diff)
		diff_label.add_theme_color_override("font_color", Color.GREEN)
	elif diff < 0:
		diff_label.text = str(diff)
		diff_label.add_theme_color_override("font_color", Color.RED)
	else:
		diff_label.text = "0"
		diff_label.add_theme_color_override("font_color", Color.WHITE)
