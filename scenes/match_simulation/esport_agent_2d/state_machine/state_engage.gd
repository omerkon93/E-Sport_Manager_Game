extends State
class_name StateEngage

# --- Variables ---
var _ttk_timer: float = 0.0
var _calculated_ttk: float = 1.0

# ==============================================================================
# STATE LIFECYCLE
# ==============================================================================

func enter() -> void:
	# Change color to yellow/orange to indicate fighting
	actor.visual_polygon.color = Color(0.8, 0.8, 0.2)
	actor.movement_component.stop()
	
	_ttk_timer = 0.0
	_calculated_ttk = _calculate_ttk() # Keeping for legacy/future use

func exit() -> void:
	# Revert color back to team colors when combat ends
	actor.visual_polygon.color = Color(0.2, 0.8, 0.2) if actor.is_team_a else Color(0.8, 0.2, 0.2)

func physics_update(delta: float) -> void:
	# 1. Check if target is dead or deleted
	if not is_instance_valid(actor.current_target) or actor.current_target.health <= 0:
		_end_combat_and_resume_mission()
		return

	# 2. Check Line of Sight (Did they run behind a wall?)
	if not actor.has_line_of_sight(actor.current_target):
		_chase_hidden_target()
		return

	# 3. Aim at the target
	var direction = actor.global_position.direction_to(actor.current_target.global_position)
	actor.rotation = direction.angle()
	
	# 4. Handle Fire Rate Cooldown
	_ttk_timer += delta
	var current_fire_rate = actor.equipped_weapon.fire_rate if actor.equipped_weapon else 0.4
	
	if _ttk_timer >= current_fire_rate:
		_fire_shot(actor.current_target)

# ==============================================================================
# STATE TRANSITIONS
# ==============================================================================

func _end_combat_and_resume_mission() -> void:
	actor.current_target = null
	print("🧠 ", actor.name, " finished combat. Resuming mission!")
	
	# Restore long-term memory waypoint
	actor.assigned_waypoint = actor.mission_waypoint
	actor.nav_component.set_destination(actor.mission_waypoint)
	
	transitioned.emit(self, "StateMove") 

func _chase_hidden_target() -> void:
	print("🧱 ", actor.name, " lost line of sight. Chasing!")
	
	# Temporarily overwrite assigned_waypoint to chase (mission_waypoint stays safe)
	actor.assigned_waypoint = actor.current_target.global_position
	actor.nav_component.set_destination(actor.assigned_waypoint)
	
	transitioned.emit(self, "StateMove")

# ==============================================================================
# COMBAT ACTIONS
# ==============================================================================

func _fire_shot(target: ESportAgent2D) -> void:
	var hit_chance = _calculate_hit_chance()
	var weapon = actor.equipped_weapon
	
	# 1. Alert nearby agents
	_broadcast_gunshot()
	
	# 2. Roll for accuracy
	if randf() <= hit_chance:
		# --- SUCCESSFUL HIT ---
		var damage = weapon.base_damage if weapon else 20.0
		damage += randf_range(-2.0, 2.0) # Add slight RNG spread
		
		target.take_damage(damage, actor)
		
		if is_instance_valid(target) and target.health > 0:
			_ttk_timer = 0.0 # Reset cooldown for next shot
		else:
			# Target died! Exit state.
			transitioned.emit(self, "StateMove")
	else:
		# --- WHIFFED SHOT ---
		print("💨 ", actor.name, " missed!")
		_ttk_timer = 0.0 
		
		# If we missed but the target didn't see us yet, the sound will alert them
		if is_instance_valid(target) and target.has_method("hear_shot_from"):
			target.hear_shot_from(actor)

func _broadcast_gunshot() -> void:
	# 500 pixels squared = 250,000. Anyone within 500 pixels hears the shot.
	var hearing_radius_sq = 250000.0 
	var all_entities = actor.get_parent().get_children()
	
	for entity in all_entities:
		if entity is ESportAgent2D and entity != actor:
			if entity.global_position.distance_squared_to(actor.global_position) < hearing_radius_sq:
				entity.hear_shot_from(actor)

# ==============================================================================
# CALCULATIONS
# ==============================================================================

func _calculate_hit_chance() -> float:
	# Force both sides to be Floats!
	var aim_stat: float = float(actor.agent_data.aim) if actor.agent_data else 50.0
	var base_chance = (aim_stat / 100.0) 
	
	if actor.equipped_weapon:
		base_chance *= actor.equipped_weapon.accuracy_multiplier
		
	return clamp(base_chance, 0.05, 0.95)

func _calculate_ttk() -> float:
	var aim_stat = float(actor.agent_data.aim if actor.agent_data else 50)
	var base_time = 2.0
	var aim_reduction = (aim_stat / 100.0) * 1.5
	var final_ttk = base_time - aim_reduction + randf_range(0.0, 0.2)
	return max(0.1, final_ttk)
