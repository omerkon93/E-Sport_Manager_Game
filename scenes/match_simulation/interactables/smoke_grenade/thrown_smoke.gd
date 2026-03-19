extends CharacterBody2D
class_name ThrownSmoke

@export var smoke_scene: PackedScene

var fuse_timer: float = 1.5 # Explodes after 1.5 seconds

func _ready() -> void:
	add_to_group("thrown_smokes")
	
	# Make the grenade spin through the air for visual flair!
	var spin_tween = create_tween().set_loops()
	spin_tween.tween_property($Polygon2D, "rotation", TAU, 0.5)

func _physics_process(delta: float) -> void:
	# 1. Apply Friction so it slows down as it slides
	velocity = velocity.move_toward(Vector2.ZERO, 400.0 * delta)
	
	# 2. Move and bounce off walls!
	var collision = move_and_collide(velocity * delta)
	if collision:
		# Bounce off the wall and lose a little bit of speed
		velocity = velocity.bounce(collision.get_normal()) * 0.7 
		
	# 3. Tick the fuse
	fuse_timer -= delta
	if fuse_timer <= 0:
		_detonate()

func _detonate() -> void:
	if smoke_scene:
		var smoke = smoke_scene.instantiate()
		get_parent().add_child(smoke)
		smoke.global_position = global_position # Spawn smoke exactly where we landed
		
	queue_free() # Destroy the grenade projectile
