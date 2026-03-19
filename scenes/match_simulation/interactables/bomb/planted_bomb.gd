extends Area2D
class_name PlantedBomb

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	# A fun visual trick: make the bomb pulse by scaling it up and down using sin()
	scale = Vector2.ONE * (1.0 + sin(Time.get_ticks_msec() / 100.0) * 0.2)

func _on_body_entered(body: Node2D) -> void:
	if body is ESportAgent2D:
		# If a CT (Team A) touches the planted bomb, tell them to defuse it!
		if body.is_team_a and not body.is_queued_for_deletion():
			body.start_defusing()
