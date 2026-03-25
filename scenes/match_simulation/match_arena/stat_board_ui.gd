extends Control
class_name StatBoardUI

# Drag your 'player_stats_board_display.tscn' into this slot in the Inspector!
@export var player_row_scene: PackedScene 

@onready var team_a_title: Label = %TeamANameLabel
@onready var team_a_stats: Control = %TeamAStats
@onready var team_b_title: Label = %TeamANameLabel
@onready var team_b_stats: Control = %TeamBStats

func _ready() -> void:
	# 1. Hide the board when the scene loads
	hide() 
	
	# 2. Existing connections...
	MatchSimulator.round_played.connect(_on_match_event)
	MatchSimulator.kill_feed_event.connect(_on_kill_event)
	MatchSimulator.match_started.connect(_on_match_started)

# --- SIGNAL RECEIVERS ---
func _on_match_started(_team_a, _team_b) -> void:
	update_board()

func _on_match_event(_r, _w, _l, _sa, _sb) -> void:
	update_board()

func _on_kill_event(_k, _v, _t) -> void:
	update_board()

# --- BOARD LOGIC ---
func update_board() -> void:
	if not is_instance_valid(MatchSimulator.active_team_a): return
	
	# Update Team Names
	team_a_title.text = MatchSimulator.active_team_a.team_name
	team_b_title.text = MatchSimulator.active_team_b.team_name
	
	# Populate both tables
	_populate_team(MatchSimulator.active_team_a.active_roster, team_a_stats)
	_populate_team(MatchSimulator.active_team_b.active_roster, team_b_stats)

func _populate_team(roster: Array, container: Control) -> void:
	# 1. Clear out the old rows
	for child in container.get_children():
		child.queue_free()
		
	# 2. Get the current round for ADR math (minimum 1 to prevent division by zero)
	var rounds = MatchSimulator.current_round - 1
	if rounds < 1: rounds = 1
	
	# 3. Create a new row for each player
	for player in roster:
		if player == null: continue
			
		var row = player_row_scene.instantiate() as PlayerStatsBoardDisplay
		container.add_child(row)
		
		# Pull their data from the MatchStats component
		var stats = MatchSimulator.stats.ledger.get(player, {"kills": 0, "deaths": 0, "damage": 0.0})
		
		# --- Ask the Economy component for their balance! ---
		var current_money = MatchSimulator.economy.get_balance(player)
		
		# Send the data to the row UI (Added current_money as the 4th argument)
		row.set_stats(player, stats, rounds, current_money)

func _unhandled_input(event: InputEvent) -> void:
	# "ui_focus_next" is Godot's default action for the TAB key
	if event.is_action_pressed("tab-key"):
		show()
		# Optional: Force a data refresh just in case!
		update_board() 
	elif event.is_action_released("tab-key"):
		hide()
