extends State
class_name StateDefuse

var _defuse_timer: float = 0.0
const DEFUSE_TIME: float = 5.0

func enter() -> void:
	actor.movement_component.stop()
	actor.visual_polygon.color = Color(0.0, 1.0, 1.0)
	_defuse_timer = 0.0
	
	# IMPORTANT: Re-connect vision during defuse!
	# Pros call this "sticking the defuse," but they still look for enemies.
	actor.vision_component.enemy_spotted.connect(_on_enemy_spotted)

func _on_enemy_spotted(target: ESportAgent2D) -> void:
	print("🚨 ", actor.name, " stopped defusing to fight!")
	actor.current_target = target
	transitioned.emit(self, "StateEngage")

func exit() -> void:
	actor.visual_polygon.color = Color(0.2, 0.8, 0.2) if actor.is_team_a else Color(0.8, 0.2, 0.2)
	if actor.vision_component.enemy_spotted.is_connected(_on_enemy_spotted):
		actor.vision_component.enemy_spotted.disconnect(_on_enemy_spotted)

func physics_update(delta: float) -> void:
	_defuse_timer += delta
	
	if _defuse_timer >= DEFUSE_TIME:
		print("✂️ THE BOMB HAS BEEN DEFUSED!")
		actor.bomb_defused.emit()
		
		# UPDATE THIS LINE: Go back to holding the angle!
		transitioned.emit(self, "StateDefend")
