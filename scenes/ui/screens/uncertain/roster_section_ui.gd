extends VBoxContainer

@export var player_row_scene: PackedScene # Drag player_roster_row.tscn here!
@onready var player_list: VBoxContainer = $PlayerList

## Clears the list and rebuilds it based on the team resource
func update_roster_display(team: ESportTeam) -> void:
	if team == null:
		push_warning("RosterSectionUI: No team resource provided!")
		return
		
	# 1. Clear old entries (in case this is called multiple times)
	for child in player_list.get_children():
		child.queue_free()
		
	# 2. Spawn a row for each player in the active roster
	for player in team.active_roster:
		var row_instance = player_row_scene.instantiate()
		player_list.add_child(row_instance)
		
		# Call the function we just wrote in the row script!
		row_instance.set_player_data(player)
