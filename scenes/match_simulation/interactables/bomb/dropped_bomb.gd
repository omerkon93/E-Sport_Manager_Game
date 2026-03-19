extends Area2D
class_name DroppedBomb

func _ready() -> void:
	# Listen for when someone steps on the bomb
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# 1. Did an Agent step on it?
	if body is ESportAgent2D:
		# 2. Are they on the T-Side (Team B) and alive?
		if not body.is_team_a and not body.is_queued_for_deletion():
			# 3. Do they already have a bomb? (Just in case!)
			if not body.is_carrying_bomb:
				body.pickup_bomb()
				
				# Destroy the dropped bomb from the ground
				queue_free()
