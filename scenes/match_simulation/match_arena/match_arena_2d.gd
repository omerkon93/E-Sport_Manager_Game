extends Node2D
class_name MatchArena2D

# ==============================================================================
# MAP DATA CONTAINER
# This script is now purely a container for the map's physical locations.
# The MatchSimulator (Autoload) will grab these points to spawn agents.
# ==============================================================================

@onready var team_a_spawn: Marker2D = %TeamASpawn
@onready var team_b_spawn: Marker2D = %TeamBSpawn

@onready var site_a: Area2D = %SiteA
@onready var site_b: Area2D = %SiteB
@onready var mid: Area2D = %Mid

@onready var nav_region: NavigationRegion2D = %NavigationRegion2D

## Helper function so the Simulator can easily ask for a spawn location!
func get_random_spawn_position(is_team_a: bool) -> Vector2:
	var base_pos = team_a_spawn.global_position if is_team_a else team_b_spawn.global_position
	var offset = Vector2(randf_range(-50, 50), randf_range(-50, 50))
	return base_pos + offset
