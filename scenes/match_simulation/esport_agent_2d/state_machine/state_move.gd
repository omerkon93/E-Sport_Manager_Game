extends State
class_name StateMove

# Track what they've thrown this specific movement phase to prevent grenade-spam
var threw_execute_smoke: bool = false
var threw_execute_flash: bool = false

func enter() -> void:
	# Reset tracking when they start a new movement
	threw_execute_smoke = false
	threw_execute_flash = false
	actor.vision_component.enemy_spotted.connect(_on_enemy_spotted)

func exit() -> void:
	actor.vision_component.enemy_spotted.disconnect(_on_enemy_spotted)
	actor.movement_component.stop()
	
func physics_update(_delta: float) -> void:
	var dist_squared = actor.global_position.distance_squared_to(actor.assigned_waypoint)
	var direction = actor.nav_component.get_movement_direction(actor.global_position)
	
	# --- 1. TACTICAL RETAKE LOGIC (CT Only) ---
	if actor._is_retaking and dist_squared < 40000.0: 
		if actor.is_team_a and actor.flashes_count > 0 and not threw_execute_flash:
			actor.flashes_count -= 1
			threw_execute_flash = true
			# Shout to the Simulator that we threw a flash!
			actor.grenade_thrown.emit("flash", actor, actor._final_bomb_pos)
			print("⚡ ", actor.agent_data.alias, " popping flash for retake!")
		
		actor.execute_retake()
		actor._is_retaking = false 
		return
	
	# --- 2. AGGRESSIVE SMOKE LOGIC (T-Side Only) ---
	# If we are within 300px (90000 squared) of our target site
	if not actor.is_team_a and dist_squared < 90000.0 and not threw_execute_smoke:
		if actor.smokes_count > 0:
			actor.smokes_count -= 1
			threw_execute_smoke = true
			
			# Throw smoke slightly ahead of the site center to block CT vision
			var smoke_target = actor.assigned_waypoint + (actor.global_position.direction_to(actor.assigned_waypoint) * 100.0)
			actor.grenade_thrown.emit("smoke", actor, smoke_target)
			print("☁️ ", actor.agent_data.alias, " executing site with smoke!")
			
	# --- 3. PROACTIVE FLASH LOGIC (CT-Side Only) ---
	# If we are within 400px (160000 squared) of our target site
	if actor.is_team_a and dist_squared < 160000.0 and not threw_execute_flash:
		if actor.flashes_count > 0:
			actor.flashes_count -= 1
			threw_execute_flash = true
			actor.grenade_thrown.emit("flash", actor, actor.assigned_waypoint)
	
	# --- 4. ARRIVAL CHECK ---
	if actor.nav_component.is_navigation_finished() or dist_squared < 2500.0:
		
		if dist_squared > 40000.0:
			actor.nav_component.set_destination(actor.assigned_waypoint)
			return
			
		if actor.is_carrying_bomb:
			transitioned.emit(self, "StatePlant")
			
		# --- THE DEFUSE FIX ---
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
