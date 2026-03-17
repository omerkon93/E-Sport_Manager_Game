extends PanelContainer
class_name ResourceDisplay

# --- CONFIGURATION ---
@export var resource_def: Resource 

# --- NODES ---
# Make sure ValueLabel and ItemInfoButton have "%" Access as Unique Name!
@onready var value_label: Label = %ValueLabel
@onready var info_button: ItemInfoButton = %ItemInfoButton

# --- STATE ---
var _displayed_value: float = 0.0
var _is_vital: bool = false
var _id: int = -1

func _ready() -> void:
	if not resource_def:
		push_warning("ResourceDisplay: No Resource assigned!")
		return

	# Setup the universal info button!
	if info_button:
		# Assuming your definitions have display_name and description properties
		info_button.setup(resource_def.display_name, resource_def.description, resource_def)
	
	if resource_def is VitalDefinition:
		_setup_vital(resource_def)
	elif resource_def is CurrencyDefinition:
		_setup_currency(resource_def)

func _setup_currency(def: CurrencyDefinition) -> void:
	_is_vital = false
	_id = def.type
	
	value_label.add_theme_color_override("font_color", def.display_color)
	CurrencyManager.currency_changed.connect(_on_currency_changed)
	
	var current = CurrencyManager.get_currency_amount(_id)
	_update_display(current, -1, false)

func _setup_vital(def: VitalDefinition) -> void:
	_is_vital = true
	_id = def.type
	
	value_label.add_theme_color_override("font_color", def.display_color)
	#VitalManager.vital_changed.connect(_on_vital_changed)
	
	#var current = VitalManager.get_current(_id)
	#var max_v = VitalManager.get_max(_id)
	#_update_display(current, max_v, false)

# --- EVENT HANDLERS ---
func _on_currency_changed(type: int, amount: float) -> void:
	if type == _id:
		_update_display(amount, -1)

func _on_vital_changed(type: int, current: float, max_val: float) -> void:
	if type == _id:
		_update_display(current, max_val)

# --- DISPLAY LOGIC ---
func _update_display(current: float, _max_val: float, animate: bool = true) -> void:
	if animate:
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		# Now it ONLY tweens the number rolling up/down!
		tween.tween_method(_set_displayed_value, _displayed_value, current, 0.5)
	else:
		_set_displayed_value(current)

func _set_displayed_value(val: float) -> void:
	_displayed_value = val
	
	if _is_vital:
		var def: VitalDefinition = resource_def
		var max_v = VitalManager.get_max(_id)
		# Output: "⚡ 50/100"
		value_label.text = "%s %d/%d" % [def.text_icon, int(val), int(max_v)]
	else:
		var def: CurrencyDefinition = resource_def
		# Output: "💵 500"
		value_label.text = "%s %d" % [def.text_icon, int(val)]
