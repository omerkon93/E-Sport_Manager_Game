extends StaticBody2D
class_name SmokeCloud

const SMOKE_DURATION: float = 8.0

func _ready() -> void:
	add_to_group("smoke_clouds")
	
	# 1. Start tiny and bloom outward!
	scale = Vector2.ZERO
	var bloom_tween = create_tween()
	bloom_tween.tween_property(self, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_SINE)
	
	# 2. Wait 8 seconds, then fade out and delete
	var fade_tween = create_tween()
	fade_tween.tween_interval(SMOKE_DURATION)
	fade_tween.tween_property(self, "modulate:a", 0.0, 1.0) # Fade to invisible
	fade_tween.tween_callback(queue_free) # Destroy the node
