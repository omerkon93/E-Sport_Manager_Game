extends PanelContainer

@export_group("Match Testing")
@export var match_popup_scene: PackedScene 
@export var enemy_team: ESportTeam         
@export var vital_definitions: Array[VitalDefinition]
@export var live_viewer_scene: PackedScene

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
	
	# Run the reset immediately when the game boots!
	_validate_match_button()

# ==============================================================================
# LIVE MATCH (With Viewer)
# ==============================================================================
func _on_play_match_button_pressed() -> void:
	if GameManager.my_team == null or not GameManager.my_team.is_match_ready():
		push_warning("Match blocked: Team is not ready!")
		return

	if enemy_team == null or match_popup_scene == null:
		push_warning("Missing resources for match simulation!")
		return
		
	_disable_match_buttons("Playing Live...")
	
	var viewer_instance = null
	if live_viewer_scene:
		viewer_instance = live_viewer_scene.instantiate()
		add_child(viewer_instance)
	
	MatchSimulator.play_live_match(GameManager.my_team, enemy_team)
	var match_results = await MatchSimulator.match_finished
	
	# --- NEW: Wait for the viewer to delete itself before showing the popup! ---
	if is_instance_valid(viewer_instance):
		await viewer_instance.tree_exited
	# ---------------------------------------------------------------------------
	
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
	
	# Notice: No Live Viewer is instantiated here!
	
	# Call a synchronous/instant simulation function instead of the live one.
	# (You will need to ensure this function exists in MatchSimulator!)
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
	# A quick helper so we don't have to write this twice!
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
	# 7 days * 24 hours * 60 minutes
	var minutes_in_week: int = 10080
	
	print("⏳ Advancing time by one week...")
	
	# This automatically triggers your SubscriptionManager to pay salaries!
	TimeManager.advance_time(minutes_in_week)
	
	# Recover the players after a rest
	VitalManager.process_weekly_recovery(GameManager.my_team)
	
	# MVP Rest Mechanic
	if GameManager.my_team != null:
		for player in GameManager.my_team.active_roster:
			if player != null:
				print(player.alias + " is fully rested for the next week.")
				# Future: Hook into your VitalsManager here to reset stress/energy
				
	print("✅ Week complete!")
