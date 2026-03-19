extends CharacterBody2D
class_name ThrownFlashbang

var fuse_timer: float = 1.0 # Flashes pop faster than smokes!

func _ready() -> void:
	add_to_group("thrown_flashes") # Group it so the Simulator can clean it up!
	
	# Make it spin
	create_tween().set_loops().tween_property($Polygon2D, "rotation", TAU, 0.5)

func _physics_process(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, 400.0 * delta)
	move_and_slide() # No bounce needed since it flies over walls
		
	fuse_timer -= delta
	if fuse_timer <= 0:
		_detonate()

func _detonate() -> void:
	print("💥 FLASHBANG POPPED!")
	
	# Ask the global simulator for everyone who is alive
	var all_living_agents = MatchSimulator.living_team_a + MatchSimulator.living_team_b
	
	var space_state = get_world_2d().direct_space_state
	
	for agent in all_living_agents:
		if is_instance_valid(agent):
			# 1. Are they within 350 pixels of the explosion?
			if global_position.distance_to(agent.global_position) < 350.0:
				
				# 2. Draw a laser from the flashbang to the agent
				var query = PhysicsRayQueryParameters2D.create(global_position, agent.global_position)
				
				# 3. ONLY hit Walls (Layer 2) and Smokes (Layer 5)
				# In Godot math: Layer 2 = 2. Layer 5 = 16. (16 + 2 = 18)
				query.collision_mask = 18 
				
				var result = space_state.intersect_ray(query)
				
				# 4. If the laser didn't hit a wall or smoke, they are BLIND!
				if result.is_empty():
					agent.get_flashed()
					
	# Create a quick visual "pop" before deleting
	$Polygon2D.scale = Vector2(3, 3)
	await get_tree().create_timer(0.1).timeout
	queue_free()
