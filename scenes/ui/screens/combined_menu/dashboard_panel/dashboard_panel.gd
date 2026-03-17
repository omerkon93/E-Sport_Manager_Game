extends PanelContainer

@export_group("Match Testing")
@export var match_popup_scene: PackedScene 
@export var enemy_team: ESportTeam         
@export var vital_definitions: Array[VitalDefinition]
@export var live_viewer_scene: PackedScene

@onready var roster_section_ui: VBoxContainer = %RosterSectionUI
@onready var play_match_button: Button = %PlayMatchButton
@onready var advance_week_button: Button = %AdvanceWeekButton

func _ready() -> void:
	# 2. Hand the definitions to the global manager FIRST
	VitalManager.initialize_vitals(vital_definitions)
	
	if GameManager.my_team != null:
		roster_section_ui.update_roster_display(GameManager.my_team)
		
	play_match_button.pressed.connect(_on_play_match_button_pressed)
	advance_week_button.pressed.connect(_on_advance_week_button_pressed)
	CurrencyManager.currency_changed.connect(func(_type, _amount): roster_section_ui.update_roster_display(GameManager.my_team))
	GameManager.roster_updated.connect(func(): roster_section_ui.update_roster_display(GameManager.my_team))
	
	SubscriptionManager.subscribe(preload("res://game_data/items/subscription/sub_salary_test.tres"))

func _on_play_match_button_pressed() -> void:
	# --- THE HARD STOP ---
	if GameManager.my_team == null or not GameManager.my_team.is_match_ready():
		push_warning("Match blocked: Team is not ready!")
		return
	# --------------------------

	if enemy_team == null or match_popup_scene == null:
		push_warning("Missing resources for match simulation!")
		return
		
	play_match_button.disabled = true
	play_match_button.text = "Playing Match..."
	
	play_match_button.disabled = true
	play_match_button.text = "Playing Match..."
	
	# --- NEW: Spawn the Live Viewer ---
	if live_viewer_scene:
		var viewer_instance = live_viewer_scene.instantiate()
		add_child(viewer_instance)
	# ----------------------------------
	
	# 1. Tell the simulator to start running in the background
	MatchSimulator.play_live_match(GameManager.my_team, enemy_team)
	
	# 2. Pause this script until the signal fires, and grab the data!
	var match_results = await MatchSimulator.match_finished
	
	# 3. Match is done! Spawn the popup
	var popup_instance = match_popup_scene.instantiate()
	add_child(popup_instance) 
	
	# 4. Pass the caught data
	popup_instance.display_results(match_results)
	
	# 5. Exhaust the players
	VitalManager.process_match_exhaustion(GameManager.my_team)
	
	# 6. Re-enable the button (by just running our validation check again)
	_validate_match_button()


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

func _validate_match_button() -> void:
	# 1. Ask the team if it's ready!
	if GameManager.my_team != null and GameManager.my_team.is_match_ready():
		play_match_button.disabled = false
		play_match_button.text = "Play Match"
	else:
		play_match_button.disabled = true
		play_match_button.text = "Roster Incomplete!"
