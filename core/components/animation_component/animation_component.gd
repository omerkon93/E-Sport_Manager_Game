extends Node
class_name AnimationComponent

# --- CONFIGURATION ---
@export var target_control: Control

# --- ANIMATION SETTINGS ---
@export_group("Shake Settings")
@export var shake_rotation_degrees: float = 3.0 # Replaced intensity with rotation
@export var shake_duration: float = 0.05

@export_group("Bounce Settings")
@export var bounce_scale: Vector2 = Vector2(0.9, 0.9)
@export var bounce_duration: float = 0.05

@export_group("Floating Text Settings")
@export var random_offset_range: float = 20.0

# Store the active tween so we can kill it if the player spams clicks!
var _active_tween: Tween

func _ready() -> void:
	if not target_control and get_parent() is Control:
		target_control = get_parent()

# ==============================================================================
# 1. SHAKE EFFECT (Errors/Failures)
# ==============================================================================
func play_shake() -> void:
	if not target_control: return
	
	_kill_active_tween()
	
	# Set the pivot to the center so it wiggles in place!
	target_control.pivot_offset = target_control.size / 2.0
	
	_active_tween = create_tween()
	
	# Wiggle using rotation to bypass Container position-locking
	_active_tween.tween_property(target_control, "rotation_degrees", shake_rotation_degrees, shake_duration)
	_active_tween.tween_property(target_control, "rotation_degrees", -shake_rotation_degrees, shake_duration * 2.0)
	_active_tween.tween_property(target_control, "rotation_degrees", 0.0, shake_duration)

# ==============================================================================
# 2. BOUNCE EFFECT (Clicks/Success)
# ==============================================================================
func play_bounce(scale_override: Vector2 = Vector2.ZERO) -> void:
	if not target_control: return
	
	_kill_active_tween()
	
	var final_scale = bounce_scale if scale_override == Vector2.ZERO else scale_override
	target_control.pivot_offset = target_control.size / 2.0
	
	_active_tween = create_tween()
	
	# Pop down, then bounce back to normal
	_active_tween.tween_property(target_control, "scale", final_scale, bounce_duration).set_trans(Tween.TRANS_SINE)
	_active_tween.tween_property(target_control, "scale", Vector2.ONE, bounce_duration).set_trans(Tween.TRANS_BOUNCE)

# ==============================================================================
# 3. HELPER: KILL TWEEN
# ==============================================================================
func _kill_active_tween() -> void:
	# Safety check: Prevent tween fighting!
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()
		# Reset to defaults immediately so it doesn't get stuck halfway
		target_control.scale = Vector2.ONE
		target_control.rotation_degrees = 0.0

# ==============================================================================
# 4. FLOATING TEXT
# ==============================================================================
func spawn_floating_text(text: String, color: Color = Color.WHITE) -> void:
	if not target_control: return
	
	var pos = target_control.get_global_mouse_position()
	pos.x += randf_range(-random_offset_range, random_offset_range)
	pos.y += randf_range(-random_offset_range, random_offset_range)
	
	SignalBus.request_floating_text.emit(pos, text, color)

@export_group("Fade Settings")
@export var fade_duration: float = 0.3

# ==============================================================================
# 5. FADE OUT & FREE (Success/Remove)
# ==============================================================================
func play_fade_out_and_free() -> void:
	if not target_control: return
	
	_kill_active_tween()
	_active_tween = create_tween()
	
	_active_tween.tween_property(target_control, "modulate:a", 0.0, fade_duration)
	_active_tween.tween_callback(target_control.queue_free)
