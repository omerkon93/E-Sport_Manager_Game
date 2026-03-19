extends State
class_name StateDefend

var scan_timer: float = 0.0
var base_rotation: float = 0.0
var is_doing_360: bool = false

func enter() -> void:
	actor.movement_component.stop()
	actor.vision_component.enemy_spotted.connect(_on_enemy_spotted)
	
	# Remember the angle we were facing when we arrived at the site
	base_rotation = actor.rotation
	scan_timer = 0.0
	is_doing_360 = false

func exit() -> void:
	actor.vision_component.enemy_spotted.disconnect(_on_enemy_spotted)

func physics_update(delta: float) -> void:
	scan_timer += delta
	
	if not is_doing_360:
		# 1. Gentle Corner Checking
		# Uses a sine wave to smoothly look back and forth by about 30 degrees
		actor.rotation = base_rotation + (sin(scan_timer * 2.0) * 0.5)
		
		# Every 5 seconds, trigger a 360 sweep!
		if scan_timer >= 5.0:
			is_doing_360 = true
			scan_timer = 0.0 # Reset timer to use for the spin duration
	else:
		# 2. The 360 Degree Sweep
		# Spin rapidly (about 180 degrees per second)
		actor.rotation += PI * delta 
		
		# After 2 seconds of spinning (a full 360), go back to holding the angle
		if scan_timer >= 2.0:
			is_doing_360 = false
			scan_timer = 0.0
			base_rotation = actor.rotation # Set our new resting angle

func _on_enemy_spotted(target: ESportAgent2D) -> void:
	actor.current_target = target
	transitioned.emit(self, "StateEngage")
