extends State
class_name StateDefuse

var _defuse_timer: float = 0.0
const DEFUSE_TIME: float = 5.0

func enter() -> void:
	actor.movement_component.stop()
	
	# Turn Cyan so we can visually see who is defusing!
	actor.visual_polygon.color = Color(0.0, 1.0, 1.0)
	_defuse_timer = 0.0

func exit() -> void:
	actor.visual_polygon.color = Color(0.2, 0.8, 0.2) if actor.is_team_a else Color(0.8, 0.2, 0.2)

func physics_update(delta: float) -> void:
	_defuse_timer += delta
	
	if _defuse_timer >= DEFUSE_TIME:
		print("✂️ THE BOMB HAS BEEN DEFUSED!")
		actor.bomb_defused.emit()
		
		# UPDATE THIS LINE: Go back to holding the angle!
		transitioned.emit(self, "StateDefend")
