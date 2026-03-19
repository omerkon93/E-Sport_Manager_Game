extends Node
class_name MovementComponent

@export var actor: CharacterBody2D
@export var movement_speed: float = 150.0

func _ready() -> void:
	# Automatically grab the parent body if we forgot to assign it in the inspector
	if not actor and get_parent() is CharacterBody2D:
		actor = get_parent()

## Applies velocity and slides the body along walls
func move(direction: Vector2) -> void:
	if not actor: return
	
	actor.velocity = direction * movement_speed
	actor.move_and_slide()

## Instantly halts all momentum
func stop() -> void:
	if not actor: return
	
	actor.velocity = Vector2.ZERO
	# Calling move_and_slide() here is optional, but ensures physics reset cleanly
	actor.move_and_slide()
