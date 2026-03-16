extends PanelContainer

@export_group("Match Testing")
@export var match_popup_scene: PackedScene 
@export var my_team: ESportTeam            
@export var enemy_team: ESportTeam         

@onready var roster_section_ui: VBoxContainer = %RosterSectionUI
@onready var play_match_button: Button = %PlayMatchButton
@onready var advance_week_button: Button = %AdvanceWeekButton 

func _ready() -> void:
	play_match_button.pressed.connect(_on_play_match_button_pressed)
	advance_week_button.pressed.connect(_on_advance_week_button_pressed)
	
	
	SubscriptionManager.subscribe(preload("res://game_data/items/subscription/sub_salary_test.tres"))
	# Since my_team is right here, we can populate the UI immediately!
	if my_team != null:
		roster_section_ui.update_roster_display(my_team)


func _on_play_match_button_pressed() -> void:
	if my_team == null or enemy_team == null or match_popup_scene == null:
		push_warning("Missing resources for match simulation!")
		return
		
	# 1. Run the math
	var match_results = MatchSimulator.play_match(my_team, enemy_team)
	
	# 2. Spawn the popup
	var popup_instance = match_popup_scene.instantiate()
	add_child(popup_instance) 
	
	# 3. Pass the data
	popup_instance.display_results(match_results)


func _on_advance_week_button_pressed() -> void:
	# 7 days * 24 hours * 60 minutes
	var minutes_in_week: int = 10080
	
	print("⏳ Advancing time by one week...")
	
	# This automatically triggers your SubscriptionManager to pay salaries!
	TimeManager.advance_time(minutes_in_week)
	
	# MVP Rest Mechanic
	if my_team != null:
		for player in my_team.active_roster:
			if player != null:
				print(player.alias + " is fully rested for the next week.")
				# Future: Hook into your VitalsManager here to reset stress/energy
				
	print("✅ Week complete!")
