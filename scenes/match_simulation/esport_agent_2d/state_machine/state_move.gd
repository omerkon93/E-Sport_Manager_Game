extends State
class_name StateMove

@export var thrown_smoke_scene: PackedScene
@export var thrown_flashbang_scene: PackedScene

func enter() -> void:
	actor.vision_component.enemy_spotted.connect(_on_enemy_spotted)

func exit() -> void:
	actor.vision_component.enemy_spotted.disconnect(_on_enemy_spotted)
	actor.movement_component.stop()
	
func physics_update(_delta: float) -> void:
	var dist_squared = actor.global_position.distance_squared_to(actor.assigned_waypoint)
	var direction = actor.nav_component.get_movement_direction(actor.global_position)
	
	# --- 1. TACTICAL RETAKE LOGIC (CT Only) ---
	if actor._is_retaking and dist_squared < 40000.0: 
		if actor.is_team_a and not actor.has_deployed_flash and thrown_flashbang_scene:
			actor.throw_flashbang_at_target(actor._final_bomb_pos, thrown_flashbang_scene)
		
		actor.execute_retake()
		actor._is_retaking = false 
		return
	
	# --- 2. AGGRESSIVE SMOKE LOGIC (T-Side Only) ---
	# If we are within 300px (90000 squared) of our target site
	if not actor.is_team_a and dist_squared < 90000.0 and not actor.has_deployed_smoke:
		if thrown_smoke_scene:
			# Tell the agent to chuck the smoke at the center of the site
			actor.throw_smoke_at_target(actor.assigned_waypoint, thrown_smoke_scene)
			
	# --- 3. PROACTIVE FLASH LOGIC (CT-Side Only) ---
	# If we are within 400px (160000 squared) of our target site
	if actor.is_team_a and dist_squared < 160000.0 and not actor.has_deployed_flash:
		if thrown_flashbang_scene:
			actor.throw_flashbang_at_target(actor.assigned_waypoint, thrown_flashbang_scene)
	
	# --- 4. ARRIVAL CHECK ---
	if actor.nav_component.is_navigation_finished() or dist_squared < 2500.0:
		
		if dist_squared > 40000.0:
			actor.nav_component.set_destination(actor.assigned_waypoint)
			return
			
		if actor.is_carrying_bomb:
			transitioned.emit(self, "StatePlant")
			
		# --- THE DEFUSE FIX ---
		# If a CT arrives exactly at the bomb coordinates, start defusing!
		elif actor.is_team_a and actor._final_bomb_pos != Vector2.ZERO and actor.assigned_waypoint == actor._final_bomb_pos:
			transitioned.emit(self, "StateDefuse")
			
		else:
			transitioned.emit(self, "StateDefend")
		return

	# --- 5. MOVEMENT EXECUTION ---
	if direction != Vector2.ZERO:
		actor.movement_component.move(direction)
		actor.rotation = direction.angle()
	else:
		actor.movement_component.stop()

func _on_enemy_spotted(target: ESportAgent2D) -> void:
	actor.current_target = target
	transitioned.emit(self, "StateEngage")
