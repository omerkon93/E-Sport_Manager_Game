extends PanelContainer
class_name PlayerVitalDisplay

# Instead of dragging a resource, we just tell it what Enum to look for
@export var vital_type: VitalDefinition.VitalType = VitalDefinition.VitalType.NONE

# --- NODES ---
@onready var value_label: Label = %ValueLabel
@onready var info_button: ItemInfoButton = %ItemInfoButton

# --- STATE ---
var _displayed_value: float = 0.0
var _target_player: ESportPlayer
var _def: VitalDefinition

func setup(player: ESportPlayer) -> void:
	_target_player = player
	
	# Fetch the static definition (Colors, Icons, Descriptions)
	_def = VitalManager.get_definition(vital_type)
	
	if _def:
		# 1. Set the color
		value_label.add_theme_color_override("font_color", _def.display_color)
		
		# 2. Setup the Universal Info Button!
		if info_button:
			info_button.setup(_def.display_name, _def.description, _def)

	# Handle empty slots
	if _target_player == null:
		value_label.text = "-/-"
		return
		
	# 3. Connect to THIS specific player's signal
	if not _target_player.vital_changed.is_connected(_on_vital_changed):
		_target_player.vital_changed.connect(_on_vital_changed)
		
	# 4. Get the initial values directly from the player
	var current: float = 0.0
	var max_val: float = 100.0
	
	if vital_type == VitalDefinition.VitalType.ENERGY:
		current = _target_player.current_energy
		max_val = _target_player.max_energy
	elif vital_type == VitalDefinition.VitalType.FOCUS:
		current = _target_player.current_focus
		max_val = _target_player.max_focus
		
	_update_display(current, max_val, false)

# --- DISPLAY LOGIC ---
func _update_display(current: float, max_val: float, animate: bool = true) -> void:
	if animate:
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		# Use bind() to safely pass the max_val to the tween step
		tween.tween_method(_tween_step.bind(max_val), _displayed_value, current, 0.5)
	else:
		_set_displayed_value(current, max_val)

# A dedicated step function for the tween to call
func _tween_step(val: float, max_val: float) -> void:
	_set_displayed_value(val, max_val)

func _set_displayed_value(val: float, max_val: float) -> void:
	_displayed_value = val
	var icon = _def.text_icon if _def else ""
	
	value_label.text = "%s %d/%d" % [icon, int(val), int(max_val)]

# --- EVENT HANDLERS ---
func _on_vital_changed(type: int, current: float, max_val: float) -> void:	
	if type == vital_type:
		_update_display(current, max_val, true)
