extends Area2D
class_name VisionComponent

signal enemy_spotted(target: ESportAgent2D)

var _my_team_is_a: bool
@onready var los_ray: RayCast2D = $LineOfSightRay

func setup(is_team_a: bool) -> void:
	_my_team_is_a = is_team_a
	
	# Wait for the agent to fully load, then tell the raycast to ignore our own body!
	call_deferred("_ignore_self")

func _ignore_self() -> void:
	if owner is CollisionObject2D:
		los_ray.add_exception(owner)

# We use _physics_process now because we need to constantly check if the smoke cleared!
func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		if body is ESportAgent2D and body != owner and not body.is_queued_for_deletion():
			if body.is_team_a != _my_team_is_a:
				
				# 1. Aim the laser at the enemy
				los_ray.target_position = to_local(body.global_position)
				los_ray.force_raycast_update() # Force physics to calculate instantly
				
				# 2. What did the laser hit?
				var collider = los_ray.get_collider()
				
				# 3. If it hit the enemy, we have a clear Line of Sight!
				if collider == body:
					enemy_spotted.emit(body as ESportAgent2D)
