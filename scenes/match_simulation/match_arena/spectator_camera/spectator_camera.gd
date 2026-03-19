extends Camera2D
class_name SpectatorCamera2D

@export var pan_speed: float = 600.0
@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.5
@export var max_zoom: float = 2.0

func _process(delta: float) -> void:
	var input_vector = Vector2.ZERO
	
	# Listen for WASD or Arrow Keys
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): input_vector.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): input_vector.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): input_vector.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): input_vector.x += 1
	
	# Move the camera independently of the agents
	if input_vector != Vector2.ZERO:
		global_position += input_vector.normalized() * pan_speed * delta

func _unhandled_input(event: InputEvent) -> void:
	# Listen for the scroll wheel to zoom in and out
	if event is InputEventMouseButton and event.is_pressed():
		var new_zoom = zoom
		
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			new_zoom += Vector2(zoom_speed, zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			new_zoom -= Vector2(zoom_speed, zoom_speed)
			
		# Clamp the zoom so we don't zoom out into the void or zoom in infinitely
		zoom = new_zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))
