extends State
class_name StatePlant

var _plant_timer: float = 0.0
const PLANT_TIME: float = 3.0

func enter() -> void:
	actor.movement_component.stop()
	
	# Turn bright orange so we can visually see who is planting!
	actor.visual_polygon.color = Color(1.0, 0.5, 0.0)
	_plant_timer = 0.0
	
	# Note: We intentionally DO NOT connect the vision cone here. 
	# They are committing to the plant and ignoring enemies!
	print(actor.name, " is planting the bomb...")

func exit() -> void:
	# If they transition out (finished planting), they return to their normal color
	actor.visual_polygon.color = Color(0.2, 0.8, 0.2) if actor.is_team_a else Color(0.8, 0.2, 0.2)

func physics_update(delta: float) -> void:
	_plant_timer += delta
	if _plant_timer >= PLANT_TIME:
		print("💣 THE BOMB HAS BEEN PLANTED!")
		actor.is_carrying_bomb = false
		
		# --- UPDATE THIS LINE ---
		actor.bomb_planted.emit(actor.global_position)
		
		transitioned.emit(self, "StateDefend")
