extends State
class_name StateEngage

var _ttk_timer: float = 0.0
var _calculated_ttk: float = 1.0

func enter() -> void:
	actor.visual_polygon.color = Color(0.8, 0.8, 0.2)
	actor.movement_component.stop()
	
	_ttk_timer = 0.0
	_calculated_ttk = _calculate_ttk()

func exit() -> void:
	actor.visual_polygon.color = Color(0.2, 0.8, 0.2) if actor.is_team_a else Color(0.8, 0.2, 0.2)

func physics_update(delta: float) -> void:
	if not is_instance_valid(actor.current_target) or actor.current_target.is_queued_for_deletion():
		transitioned.emit(self, "StateMove")
		return

	var direction = actor.global_position.direction_to(actor.current_target.global_position)
	actor.rotation = direction.angle()
	
	_ttk_timer += delta
	
	# --- NEW: Use the Weapon's specific Fire Rate! ---
	var current_fire_rate = actor.equipped_weapon.fire_rate if actor.equipped_weapon else 0.4
	
	if _ttk_timer >= current_fire_rate:
		_fire_shot(actor.current_target)

func _fire_shot(target: ESportAgent2D) -> void:
	var hit_chance = _calculate_hit_chance()
	var roll = randf() 
	var weapon_name = actor.equipped_weapon.weapon_name if actor.equipped_weapon else "Gun"
	
	if roll <= hit_chance:
		print("🎯 ", actor.name, " fired their ", weapon_name, " and HIT! (Chance: ", round(hit_chance * 100), "%)")
		target.die(actor) 
		transitioned.emit(self, "StateMove")
	else:
		print("💨 ", actor.name, " whiffed their ", weapon_name, " shot! Recoil resetting...")
		_ttk_timer = 0.0 
		
		if is_instance_valid(target) and target.has_method("hear_shot_from"):
			target.hear_shot_from(actor)

func _calculate_ttk() -> float:
	var aim_stat = float(actor.agent_data.aim if actor.agent_data else 50)
	var base_time = 2.0
	var aim_reduction = (aim_stat / 100.0) * 1.5
	var final_ttk = base_time - aim_reduction + randf_range(0.0, 0.2)
	return max(0.1, final_ttk)

# --- NEW: Calculate how accurate they are ---
func _calculate_hit_chance() -> float:
	var aim_stat = actor.agent_data.aim if actor.agent_data else 50.0
	var base_chance = (aim_stat / 100.0) 
	
	# Apply the weapon's unique accuracy multiplier
	if actor.equipped_weapon:
		base_chance *= actor.equipped_weapon.accuracy_multiplier
		
	# Keep the final hit chance between 5% and 95% so there is always a tiny bit of RNG
	return clamp(base_chance, 0.05, 0.95)
