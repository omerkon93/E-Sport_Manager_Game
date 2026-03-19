extends State
class_name StateBlinded

var _blind_timer: float = 0.0
const BLIND_DURATION: float = 2.0

func enter() -> void:
	actor.movement_component.stop()
	
	# Turn bright white to show they are flashed!
	actor.visual_polygon.color = Color(1.0, 1.0, 1.0)
	_blind_timer = 0.0
	
	# Clear their memory so they forget who they were shooting at
	actor.current_target = null 
	
	print("😵 ", actor.name, " is BLINDED!")

func exit() -> void:
	actor.visual_polygon.color = Color(0.2, 0.8, 0.2) if actor.is_team_a else Color(0.8, 0.2, 0.2)

func physics_update(delta: float) -> void:
	_blind_timer += delta
	
	if _blind_timer >= BLIND_DURATION:
		# When the flash wears off, go back to moving. 
		# (If they are already at the site, StateMove will instantly pass them to StateDefend)
		transitioned.emit(self, "StateMove")
