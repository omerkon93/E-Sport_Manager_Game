extends VBoxContainer # Or whatever your root node is!

@export var player_row_scene: PackedScene

# Grab references to both lists
@onready var active_list: VBoxContainer = %ActiveList
@onready var bench_list: VBoxContainer = %BenchList


func update_roster_display(team: ESportTeam) -> void:
	_clear_container(active_list)
	_clear_container(bench_list)
	if team == null: return
	
	# Active roster gets 'false'
	for player in team.active_roster:
		_add_player_row(player, active_list, false) 
		
	# Bench gets 'true'
	for player in team.bench:
		_add_player_row(player, bench_list, true)

func _add_player_row(player: ESportPlayer, container: Container, is_benched: bool) -> void:
	var row = player_row_scene.instantiate()
	container.add_child(row)
	if row.has_method("set_player_data"):
		row.set_player_data(player, is_benched) # Pass the flag!

func _clear_container(container: Container) -> void:
	if container:
		for child in container.get_children():
			child.queue_free()
