extends CanvasLayer
class_name MatchHUD

@onready var team_a_label: Label = %TeamALabel
@onready var round_label: Label = %RoundLabel
@onready var team_b_label: Label = %TeamBLabel
@onready var bomb_timer_label: Label = %BombTimerLabel
@onready var team_a_roster: HBoxContainer = %TeamARoster
@onready var team_b_roster: HBoxContainer = %TeamBRoster


@export var player_panel_scene: PackedScene

# Grab our new Kill Feed container!
@onready var kill_feed_container: VBoxContainer = %KillFeedContainer

func _ready() -> void:
	bomb_timer_label.hide()
	team_a_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2)) 
	team_b_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2)) 
	round_label.add_theme_font_size_override("font_size", 24)
	
	MatchSimulator.round_played.connect(_on_round_played) # Reusing this for now, but better to have a specific 'round_started' signal
	MatchSimulator.kill_feed_event.connect(_on_kill_feed_event)
	
	# For immediate setup on round 1:
	MatchSimulator.round_started.connect(_build_rosters)

func _process(_delta: float) -> void:
	# 1. Safely grab team names (fallback to "Team A/B" if null)
	var name_a = MatchSimulator.active_team_a.team_name if MatchSimulator.active_team_a else "Team A"
	var name_b = MatchSimulator.active_team_b.team_name if MatchSimulator.active_team_b else "Team B"
	
	# 2. Update the Scoreboard
	team_a_label.text = "%s : %d" % [name_a, MatchSimulator.score_a]
	team_b_label.text = "%d : %s" % [MatchSimulator.score_b, name_b]
	
	# 3. Update the Round Counter
	round_label.text = "ROUND %d / %d" % [MatchSimulator.current_round, MatchSimulator.MAX_ROUNDS]
	
	# 4. Process the Bomb Timer!
	if MatchSimulator.is_bomb_planted:
		bomb_timer_label.show()
		
		# Format the float to show exactly 1 decimal place (e.g., "39.5 s")
		bomb_timer_label.text = "⚠ C4 PLANTED: %.1f s" % MatchSimulator.c4_timer
		
		# Dynamic Colors! Make it flash red when under 10 seconds!
		if MatchSimulator.c4_timer <= 10.0:
			# Flashes between White and Red quickly
			var flash = sin(Time.get_ticks_msec() / 50.0) 
			bomb_timer_label.modulate = Color(1.0, flash, flash) 
		else:
			bomb_timer_label.modulate = Color(1.0, 0.5, 0.0) # Solid Orange
	else:
		bomb_timer_label.hide()
	pass

func _on_kill_feed_event(killer_name: String, victim_name: String, killer_is_team_a: bool) -> void:
	var kill_label = Label.new()
	kill_label.text = killer_name + "  ⚔️  " + victim_name
	
	# Align it to the right side of the screen
	kill_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	
	# Color code the text based on who got the kill
	if killer_is_team_a:
		kill_label.modulate = Color(0.2, 0.8, 0.2) # CT Green
	else:
		kill_label.modulate = Color(0.8, 0.2, 0.2) # T Red
		
	# Add it to the screen
	kill_feed_container.add_child(kill_label)
	
	# Create a simple Tween to fade it out and delete it after 4 seconds
	var tween = create_tween()
	tween.tween_interval(3.0) # Wait 3 seconds
	tween.tween_property(kill_label, "modulate:a", 0.0, 1.0) # Fade alpha to 0 over 1 second
	tween.tween_callback(kill_label.queue_free) # Delete the label

func _on_round_played(_round_num: int, winner_name: String, _log_text: String, _score_a: int, _score_b: int) -> void:
	print("📺 HUD: Round over! Winner: ", winner_name)
	
	# Optional: Clear the kill feed instantly when the round ends
	for child in kill_feed_container.get_children():
		child.queue_free()
		
# ==============================================================================
# ROSTER OVERLAY
# ==============================================================================
func _build_rosters() -> void:
	
	print("📺 HUD: Building rosters! CTs alive: ", MatchSimulator.living_team_a.size(), " | Ts alive: ", MatchSimulator.living_team_b.size())
	# 1. Clear out any old panels from the previous round
	for child in team_a_roster.get_children(): child.queue_free()
	for child in team_b_roster.get_children(): child.queue_free()
		
	# 2. Build Team A (CT)
	for agent in MatchSimulator.living_team_a:
		var panel = player_panel_scene.instantiate() as PlayerHUDPanel
		team_a_roster.add_child(panel)
		panel.setup(agent)
		
	# 3. Build Team B (T)
	for agent in MatchSimulator.living_team_b:
		var panel = player_panel_scene.instantiate() as PlayerHUDPanel
		team_b_roster.add_child(panel)
		panel.setup(agent)
		
		# Optional: Flip the T-side UI to align right!
		panel.size_flags_horizontal = Control.SIZE_SHRINK_END
