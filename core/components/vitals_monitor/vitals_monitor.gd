extends Node
class_name VitalMonitor

signal data_updated(current: float, max_val: float, bar_color: Color)

var vital_type: int = VitalDefinition.VitalType.NONE
var gradient: GradientTexture1D 
var target_player: ESportPlayer # Now it tracks a specific person!

func setup(type: int, grad_texture: GradientTexture1D, player: ESportPlayer) -> void:
	vital_type = type
	gradient = grad_texture
	target_player = player
	
	if target_player == null:
		return
		
	# 1. Connect directly to the PLAYER'S signal, not the global manager
	if not target_player.vital_changed.is_connected(_on_vital_changed):
		target_player.vital_changed.connect(_on_vital_changed)
	
	# 2. Initial Fetch
	var current: float = target_player.current_energy if type == VitalDefinition.VitalType.ENERGY else target_player.current_focus
	var max_val: float = target_player.max_energy if type == VitalDefinition.VitalType.ENERGY else target_player.max_focus
		
	_process_update(current, max_val)

func _on_vital_changed(type: int, current: float, max_val: float) -> void:
	if type == vital_type:
		_process_update(current, max_val)

func _process_update(current: float, max_val: float) -> void:
	var color: Color = Color.WHITE
	if gradient and gradient.gradient:
		var percent: float = 0.0 if max_val == 0 else current / max_val
		color = gradient.gradient.sample(percent)
	
	data_updated.emit(current, max_val, color)
