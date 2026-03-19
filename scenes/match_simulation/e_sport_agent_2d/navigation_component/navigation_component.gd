extends NavigationAgent2D
class_name NavigationComponent

func _ready() -> void:
	# Keep our settings centralized here!
	path_desired_distance = 10.0
	target_desired_distance = 10.0

## Sets the final destination for the pathfinder
func set_destination(target_point: Vector2) -> void:
	target_position = target_point

## Returns a normalized Vector2 pointing to the very next step on the path
func get_movement_direction(current_global_pos: Vector2) -> Vector2:
	if is_navigation_finished():
		return Vector2.ZERO
		
	var next_path_position: Vector2 = get_next_path_position()
	return current_global_pos.direction_to(next_path_position)
