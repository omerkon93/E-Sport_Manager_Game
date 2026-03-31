extends Control
class_name ScheduleUI

@export var schedule_row_scene: PackedScene

# Left Side
@onready var daily_list: VBoxContainer = %DailyList
@onready var prev_button: Button = %PrevButton
@onready var next_button: Button = %NextButton
@onready var day_title_label: Label = %DayTitleLabel

# Right Side
@onready var player_list: VBoxContainer = %PlayerList

var viewing_day: int = 1
var max_season_days: int = 1

func _ready() -> void:
	LeagueManager.standings_updated.connect(_on_standings_updated)
	
	TimeManager.day_started.connect(_on_day_started)
	
	prev_button.pressed.connect(_on_prev_pressed)
	next_button.pressed.connect(_on_next_pressed)
	
	if not LeagueManager.schedule.is_empty():
		var last_week = LeagueManager.schedule.back()
		if not last_week.is_empty():
			max_season_days = last_week[0].get("scheduled_day", LeagueManager.schedule.size())
		
		viewing_day = TimeManager.current_day 
		_build_schedule()

func _on_standings_updated() -> void:
	viewing_day = TimeManager.current_day
	_build_schedule()

# --- NEW: Refresh the UI when the day changes! ---
func _on_day_started(_new_day: int) -> void:
	# Optional: Automatically snap the left calendar view back to "Today"
	viewing_day = TimeManager.current_day
	
	# Redraw all the rows so "Upcoming" turns into "UP NEXT"
	_build_schedule()

func _on_prev_pressed() -> void:
	if viewing_day > 1:
		viewing_day -= 1
		_build_schedule()

func _on_next_pressed() -> void:
	if viewing_day < max_season_days:
		viewing_day += 1
		_build_schedule()

func _build_schedule() -> void:
	if GameManager.my_team == null or LeagueManager.schedule.is_empty():
		return
		
	_build_daily_view()
	_build_player_season_view()

func _build_daily_view() -> void:
	day_title_label.text = "Calendar Day " + str(viewing_day)
	prev_button.disabled = (viewing_day <= 1)
	next_button.disabled = (viewing_day >= max_season_days)
		
	for child in daily_list.get_children():
		child.queue_free()
		
	# Scan the whole schedule for matches happening ON THIS EXACT DAY
	var matches_today = []
	for week_matches in LeagueManager.schedule:
		for match_dict in week_matches:
			if match_dict.get("scheduled_day", 1) == viewing_day:
				matches_today.append(match_dict)
				
	# If no matches are scheduled today, show a Rest Day message!
	if matches_today.is_empty():
		var rest_label = Label.new()
		rest_label.text = "- Rest Day -"
		rest_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rest_label.add_theme_color_override("font_color", Color.GRAY)
		daily_list.add_child(rest_label)
	else:
		for match_dict in matches_today:
			var row = schedule_row_scene.instantiate() as ScheduleRow
			daily_list.add_child(row)
			row.set_schedule_data(viewing_day, match_dict["home"], match_dict["away"], TimeManager.current_day, match_dict)

func _build_player_season_view() -> void:
	for child in player_list.get_children():
		child.queue_free()
		
	for week_matches in LeagueManager.schedule:
		for match_dict in week_matches:
			var home_name = match_dict["home"].team_name
			var away_name = match_dict["away"].team_name
			var my_name = GameManager.my_team.team_name
			
			if home_name == my_name or away_name == my_name:
				var row = schedule_row_scene.instantiate() as ScheduleRow
				player_list.add_child(row)
				
				# Grab the exact day from the dictionary (1, 3, 5, etc)
				var target_day = match_dict.get("scheduled_day", 1)
				
				row.set_schedule_data(target_day, match_dict["home"], match_dict["away"], TimeManager.current_day, match_dict)
				break
