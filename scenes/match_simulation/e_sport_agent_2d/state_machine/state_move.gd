extends State
class_name StateMove

@export var thrown_smoke_scene: PackedScene
@export var thrown_flashbang_scene: PackedScene

func enter() -> void:
	actor.vision_component.enemy_spotted.connect(_on_enemy_spotted)
	# (Notice we removed the inventory reset from here!)

func exit() -> void:
	actor.vision_component.enemy_spotted.disconnect(_on_enemy_spotted)
	actor.movement_component.stop()

func physics_update(_delta: float) -> void:
	var distance_to_target = actor.global_position.distance_to(actor.assigned_waypoint)
	var direction = actor.nav_component.get_movement_direction(actor.global_position)
	
	# --- EXISTING SMOKE LOGIC FOR T-SIDE ---
	if distance_to_target < 300.0 and not actor.has_deployed_smoke:
		if not actor.is_team_a and thrown_smoke_scene:
			actor.has_deployed_smoke = true
			var nade = thrown_smoke_scene.instantiate()
			actor.get_parent().add_child(nade)
			nade.global_position = actor.global_position
			nade.velocity = direction * 540.0 
			
	# --- NEW FLASHBANG LOGIC FOR CT-SIDE ---
	if distance_to_target < 400.0 and not actor.has_deployed_flash:
		if actor.is_team_a and thrown_flashbang_scene:
			actor.has_deployed_flash = true
			var flash = thrown_flashbang_scene.instantiate()
			actor.get_parent().add_child(flash)
			flash.global_position = actor.global_position
			# Throw it forward, over the walls!
			flash.velocity = direction * 800.0 
			print("⚡ ", actor.name, " threw a Flashbang!")

	# 3. Check for arrival
	if actor.nav_component.is_navigation_finished():
		if distance_to_target < 50.0:
			if actor.is_carrying_bomb:
				transitioned.emit(self, "StatePlant")
			else:
				transitioned.emit(self, "StateDefend")
			return
		else:
			actor.movement_component.stop()
			return

	# 4. Standard Movement
	if direction != Vector2.ZERO:
		actor.movement_component.move(direction)
		actor.rotation = direction.angle()
	else:
		actor.movement_component.stop()

func _on_enemy_spotted(target: ESportAgent2D) -> void:
	actor.current_target = target
	transitioned.emit(self, "StateEngage")
