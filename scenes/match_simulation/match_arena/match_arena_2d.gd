extends Node2D
class_name MatchArena2D

# ==============================================================================
# MAP DATA CONTAINER
# ==============================================================================

@onready var team_a_spawn: Node2D = %TeamASpawn
@onready var team_b_spawn: Node2D = %TeamBSpawn

@onready var site_a: Area2D = %SiteA
@onready var site_b: Area2D = %SiteB
@onready var mid: Area2D = %Mid

@onready var nav_region: NavigationRegion2D = %NavigationRegion2D

# --- Group tactical locations for easy querying by the Simulator ---
@onready var tactical_locations: Dictionary = {
	"A": %SiteA,
	"B": %SiteB,
	"Mid": %Mid
}

# --- Track who is standing where ---
# Key: Marker2D (The spot) -> Value: ESportAgent2D (The player holding it)
var claimed_angles: Dictionary = {}

# ==============================================================================
# SPAWN LOGIC
# ==============================================================================
func get_fixed_spawn_position(is_team_a: bool, player_index: int) -> Vector2:
	var base_node = team_a_spawn if is_team_a else team_b_spawn
	
	# 1. Strictly filter for ONLY Marker2D nodes
	var spawns = []
	for child in base_node.get_children():
		if child is Marker2D:
			spawns.append(child)
	
	# 2. Assign the specific marker
	if spawns.size() > 0:
		var safe_index = player_index % spawns.size()
		var chosen_marker = spawns[safe_index]
		
		return chosen_marker.global_position
		
	push_warning("⚠️ No Marker2Ds found for is_team_a: ", is_team_a)
	return base_node.global_position

# ==============================================================================
# TACTICAL QUERY LOGIC
# ==============================================================================

## Returns the exact center of the site (used for planting the bomb)
func get_site_center(site_name: String) -> Vector2:
	if tactical_locations.has(site_name):
		return tactical_locations[site_name].global_position
	return global_position 

## Finds an empty defensive position for an agent to hold
func claim_defensive_angle(site_name: String, agent: ESportAgent2D) -> Vector2:
	var fallback_pos = get_site_center(site_name)
	
	if not tactical_locations.has(site_name): return fallback_pos
	
	var site_node = tactical_locations[site_name]
	var angles_folder = site_node.get_node_or_null("DefensiveAngles")
	
	# If we haven't built angles for this site yet in the editor, just use the center
	if not angles_folder or angles_folder.get_child_count() == 0:
		return _get_safe_random_offset(fallback_pos)
		
	var available_markers = []
	
	# 1. Scan all markers to see which ones are empty
	for marker in angles_folder.get_children():
		# A marker is empty if it's not in the dictionary, OR if the agent who claimed it is dead/freed
		if not claimed_angles.has(marker) or not is_instance_valid(claimed_angles[marker]):
			available_markers.append(marker)
			
	# 2. Pick a random available angle and claim it!
	if available_markers.size() > 0:
		var chosen_spot = available_markers.pick_random()
		claimed_angles[chosen_spot] = agent
		return chosen_spot.global_position
		
	# 3. If all 5 CTs are on a site with only 3 spots, the remaining 2 get a random offset nearby
	return _get_safe_random_offset(fallback_pos)

## A helper to ensure our fallbacks don't spawn agents inside walls
func _get_safe_random_offset(base_pos: Vector2) -> Vector2:
	var offset = Vector2(randf_range(-60, 60), randf_range(-60, 60))
	var raw_pos = base_pos + offset
	
	var nav_map_rid = get_world_2d().navigation_map
	
	if NavigationServer2D.map_get_iteration_id(nav_map_rid) == 0:
		return raw_pos 
		
	var safe_pos = NavigationServer2D.map_get_closest_point(nav_map_rid, raw_pos)
	
	if safe_pos == Vector2.ZERO or not safe_pos.is_finite():
		return raw_pos
		
	return safe_pos

## Optional: Manually clear the board at the start of a round
func reset_angles() -> void:
	claimed_angles.clear()
