extends Polygon2D

@export var radius: float = 10.0
@export var segments: int = 32

func _ready() -> void:
	var points = PackedVector2Array()
	for i in range(segments):
		var angle = (i / float(segments)) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	
	polygon = points
