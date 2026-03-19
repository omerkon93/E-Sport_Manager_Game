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
		
	play_match_button.pressed.connect(_on_play_match_button_pressed)
	advance_week_button.pressed.connect(_on_advance_week_button_pressed)
	play_now_button.pressed.connect(_on_play_now_button_pressed)
	
	CurrencyManager.currency_changed.connect(func(_type, _amount): roster_section_ui.update_roster_display(GameManager.my_team))
	GameManager.roster_updated.connect(func(): 
		roster_section_ui.update_roster_display(GameManager.my_team)
		_validate_match_button()
	)
	
	SubscriptionManager.subscribe(preload("res://game_data/subscriptions/sub_salary_test.tres"))
	
	_validate_match_button()

# ==============================================================================
# LIVE MATCH (With Viewer)
# ==============================================================================
func _on_play_match_button_pressed() -> void:
	if GameManager.my_team == null or not GameManager.my_team.is_match_ready(): return
	
	if live_viewer_scene == null or match_hud_scene == null:
		push_error("Missing scenes! Assign the Map and HUD in the inspector.")
		return
		
	_disable_match_buttons("Playing Live...")
	
	# 1. HIDE THE DASHBOARD! This stops the UI from bleeding through.
	# We need to hide the top-level parent (CombinedMenu) so everything disappears.
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
		
	# 2. ADD TO THE ROOT! This frees the map from the UI's layout rules.
	get_tree().root.add_child(arena_instance)
	get_tree().root.add_child(hud_instance) 
	
	MatchSimulator.play_live_match(arena_instance, GameManager.my_team, enemy_team)
	
	var match_results = await MatchSimulator.match_finished
	
	# 3. Destroy both when the match is over!
	arena_instance.queue_free()
	hud_instance.queue_free()
	
	# 4. SHOW THE DASHBOARD AGAIN!
	root_menu.show()
	_show_results_and_cleanup(match_results)

# ==============================================================================
# QUICK SIM MATCH (Instant)
# ==============================================================================
func _on_play_now_button_pressed() -> void:
	if GameManager.my_team == null or not GameManager.my_team.is_match_ready():
		push_warning("Match blocked: Team is not ready!")
		return

	if enemy_team == null or match_popup_scene == null:
		push_warning("Missing resources for match simulation!")
		return
		
	_disable_match_buttons("Simulating...")
	
	var match_results = MatchSimulator.quick_simulate_match(GameManager.my_team, enemy_team)
	
	_show_results_and_cleanup(match_results)

# ==============================================================================
# SHARED HELPERS
# ==============================================================================
func _show_results_and_cleanup(match_results) -> void:
	var popup_instance = match_popup_scene.instantiate()
	add_child(popup_instance) 
	
	popup_instance.display_results(match_results)
	VitalManager.process_match_exhaustion(GameManager.my_team)
	
	_validate_match_button()

func _disable_match_buttons(text: String) -> void:
	play_match_button.disabled = true
	play_now_button.disabled = true
	play_match_button.text = text
	play_now_button.text = text

func _validate_match_button() -> void:
	if GameManager.my_team != null and GameManager.my_team.is_match_ready():
		play_match_button.disabled = false
		play_now_button.disabled = false
		play_match_button.text = "Watch Live"
		play_now_button.text = "Quick Sim"
	else:
		play_match_button.disabled = true
		play_now_button.disabled = true
		play_match_button.text = "Roster Incomplete!"
		play_now_button.text = "Roster Incomplete!"

func _on_advance_week_button_pressed() -> void:
	var minutes_in_week: int = 10080
	print("⏳ Advancing time by one week...")
	TimeManager.advance_time(minutes_in_week)
	VitalManager.process_weekly_recovery(GameManager.my_team)
	
	if GameManager.my_team != null:
		for player in GameManager.my_team.active_roster:
			if player != null:
				print(player.alias + " is fully rested for the next week.")
				
	print("✅ Week complete!")
