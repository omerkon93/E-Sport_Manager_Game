extends PanelContainer

@export_group("Match Testing")
@export var match_popup_scene: PackedScene 
@export var enemy_team: ESportTeam         
@export var vital_definitions: Array[VitalDefinition]
@export var live_viewer_scene: PackedScene
@export var match_hud_scene: PackedScene

@onready var roster_section_ui: VBoxContainer = %RosterSectionUI
@onready var play_match_button: Button = %PlayMatchButton
@onready var advance_week_button: Button = %AdvanceWeekButton
@onready var play_now_button: Button = %PlayNowButton 

func _ready() -> void:
	VitalManager.initialize_vitals(vital_definitions)
	
	if GameManager.my_team != null:
		roster_section_ui.update_roster_display(GameManager.my_team)
		
		# Tell the LeagueManager to scan the folders and build the league!
		# (This automatically calls start_new_season internally)
		LeagueManager.initialize_league(GameManager.my_team)
		
	play_match_button.pressed.connect(_on_play_match_button_pressed)
	advance_week_button.pressed.connect(_on_advance_day_button_pressed)
	play_now_button.pressed.connect(_on_play_now_button_pressed)
	
	CurrencyManager.currency_changed.connect(func(_type, _amount): roster_section_ui.update_roster_display(GameManager.my_team))
	GameManager.roster_updated.connect(func(): 
		roster_section_ui.update_roster_display(GameManager.my_team)
		_validate_match_button()
	)
	
	SubscriptionManager.subscribe(preload("res://game_data/subscriptions/sub_salary_test.tres"))
	
	# REMOVED the old manual "start_new_season" test code from here!


# ==========================================
# NEW HELPER: Find out who we play this week!
# ==========================================
func _get_current_match_data() -> Dictionary:
	if LeagueManager.current_week - 1 >= LeagueManager.schedule.size():
		print("❌ FAILED: Schedule is empty or season is over!")
		return {} 
		
	var week_idx = LeagueManager.current_week - 1
	var week_matches = LeagueManager.schedule[week_idx]
	var my_name = GameManager.my_team.team_name
	
	print("3. Searching for '", my_name, "' in Week Index ", week_idx)
	
	for match_pair in week_matches:
		var home_name = match_pair["home"].team_name
		var away_name = match_pair["away"].team_name
		print("   -> Checking match: ", home_name, " vs ", away_name)
		
		if home_name == my_name or away_name == my_name:
			var target_day = match_pair.get("scheduled_day", "ERROR")
			print("✅ SUCCESS: Found match! Scheduled for Day: ", target_day)
			return match_pair
			
	print("❌ FAILED: Could not find player team in this week's matches!")
	return {}

# ==============================================================================
# QUICK SIM MATCH (Instant)
# ==============================================================================
func _on_play_now_button_pressed() -> void:
	if GameManager.my_team == null or not GameManager.my_team.is_match_ready():
		push_warning("Match blocked: Team is not ready!")
		return

	# 1. Get the match dictionary
	var match_data = _get_current_match_data()
	if match_data.is_empty():
		push_warning("Missing match data or season is over!")
		return
		
	# 2. EXTRACT THE ENEMY TEAM!
	# If we are the home team, the enemy is away. Otherwise, the enemy is home.
	var current_enemy = match_data["away"] if match_data["home"] == GameManager.my_team else match_data["home"]
		
	_disable_match_buttons("Simulating...")
	
	# 3. Pass the extracted enemy team (not the dictionary) to the simulator!
	var match_results = MatchSimulator.quick_simulate_match(GameManager.my_team, current_enemy)
	
	_show_results_and_cleanup(match_results)


# ==============================================================================
# LIVE MATCH (With Viewer)
# ==============================================================================
func _on_play_match_button_pressed() -> void:
	if GameManager.my_team == null or not GameManager.my_team.is_match_ready(): return
	
	# 1. Get the match dictionary
	var match_data = _get_current_match_data()
	if match_data.is_empty():
		push_warning("No opponent found! Is the season over?")
		return
		
	# 2. EXTRACT THE ENEMY TEAM!
	var current_enemy = match_data["away"] if match_data["home"] == GameManager.my_team else match_data["home"]
	
	if live_viewer_scene == null or match_hud_scene == null:
		push_error("Missing scenes! Assign the Map and HUD in the inspector.")
		return
		
	_disable_match_buttons("Playing Live...")
	
	var root_menu = owner if owner else self
	root_menu.hide()
	
	var arena_instance = live_viewer_scene.instantiate()
	var hud_instance = match_hud_scene.instantiate()
	
	if not arena_instance is MatchArena2D:
		push_error("Assigned scene is NOT a MatchArena2D!")
		arena_instance.queue_free()
		hud_instance.queue_free()
		root_menu.show() 
		_validate_match_button()
		return
		
	get_tree().root.add_child(arena_instance)
	get_tree().root.add_child(hud_instance) 
	
	# 3. Pass the extracted enemy team (not the dictionary) to the live simulator!
	MatchSimulator.play_live_match(arena_instance, GameManager.my_team, current_enemy)
	
	var match_results = await MatchSimulator.match_finished
	
	arena_instance.queue_free()
	hud_instance.queue_free()
	
	root_menu.show()
	_show_results_and_cleanup(match_results)


# ==============================================================================
# SHARED HELPERS
# ==============================================================================
func _show_results_and_cleanup(match_results) -> void:
	# ==========================================
	# 1. SHOW THE UI POPUP
	# ==========================================
	var popup_instance = match_popup_scene.instantiate()
	add_child(popup_instance) 
	popup_instance.display_results(match_results)
	
	# ==========================================
	# 2. RECORD PLAYER MATCH
	# ==========================================
	var team_a = match_results["team_a"]
	var team_b = match_results["team_b"]
	var score_a = match_results["score_a"]
	var score_b = match_results["score_b"]
	
	# Manually record our score into the League Manager FIRST!
	LeagueManager.record_match_result(team_a, team_b, score_a, score_b)
	
	# ==========================================
	# 3. SIMULATE THE REST OF THE LEAGUE
	# ==========================================
	# Now that our score is saved, tell the AI to play the rest of the week's matches
	LeagueManager.simulate_ai_matches_for_week(GameManager.my_team)
	
	# ==========================================
	# 4. CLEANUP & EXHAUSTION
	# ==========================================
	VitalManager.process_match_exhaustion(GameManager.my_team)
	
	# ==========================================
	# 5. TIME PASSAGE
	# ==========================================
	# Mark today as a played day so the buttons lock!
	LeagueManager.last_match_played_day = TimeManager.current_day
	
	print("⏳ Match complete. 2 hours have passed.")
	TimeManager.advance_time(120)
	
	_validate_match_button()

func _disable_match_buttons(text: String) -> void:
	play_match_button.disabled = true
	play_now_button.disabled = true
	play_match_button.text = text
	play_now_button.text = text

func _validate_match_button() -> void:
	# ==========================================
	# 1. Check if Roster is Complete
	# ==========================================
	if GameManager.my_team == null or not GameManager.my_team.is_match_ready():
		play_match_button.disabled = true
		play_now_button.disabled = true
		play_match_button.text = "Roster Incomplete!"
		play_now_button.text = "Roster Incomplete!"
		return # Stop here, don't check anything else!

	# ==========================================
	# 2. Check the Calendar Date
	# ==========================================
	var next_match = _get_current_match_data()
	if not next_match.is_empty():
		var target_day = next_match.get("scheduled_day", 1)
		
		# Assuming your TimeManager has a 'current_day' variable
		if TimeManager.current_day < target_day:
			play_now_button.disabled = true
			play_match_button.disabled = true
			play_match_button.text = "Match is Day " + str(target_day)
			play_now_button.text = "Match is Day " + str(target_day)
			return # Stop here!

	# ==========================================
	# 3. Check the Time of Day
	# ==========================================
	# Assuming your TimeManager has a 'current_hour' variable
	if TimeManager.current_hour >= 22 or TimeManager.current_hour < 6:
		play_now_button.disabled = true
		play_match_button.disabled = true
		play_match_button.text = "Too Late! Sleep."
		play_now_button.text = "Too Late! Sleep."
		return # Stop here!
		
	# ==========================================
	# 4. Did we already play today?
	# ==========================================
	if LeagueManager.last_match_played_day == TimeManager.current_day:
		play_now_button.disabled = true
		play_match_button.disabled = true
		play_match_button.text = "Done for today. Sleep."
		play_now_button.text = "Done for today. Sleep."
		return # Stop here!
	
	# ==========================================
	# 5. All Checks Passed! Ready to Play!
	# ==========================================
	play_match_button.disabled = false
	play_now_button.disabled = false
	play_match_button.text = "Watch Live"
	play_now_button.text = "Quick Sim"

func _on_advance_day_button_pressed() -> void:
	# Calculate how many minutes until 8:00 AM the next day
	var hours_until_midnight = 24 - TimeManager.current_hour
	var minutes_to_add = (hours_until_midnight * 60) - TimeManager.current_minute + (8 * 60) # 8 hours for 8:00 AM
	
	print("🌙 Going to sleep... Advancing to next day.")
	TimeManager.advance_time(minutes_to_add)
	
	# Heal your players overnight!
	# (You can write a custom 'process_daily_recovery' in VitalManager for this)
	VitalManager.process_weekly_recovery(GameManager.my_team) 
	
	# Maybe the Market generates 1 new rookie every day instead of every week?
	MarketManager.generate_weekly_rookies(1)
	
	_validate_match_button()
