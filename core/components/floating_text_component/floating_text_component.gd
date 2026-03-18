extends CanvasLayer
class_name FloatingTextComponent

# Use PackedScene so we can spawn new copies of the text
@export var floating_text_scene: PackedScene

func _ready() -> void:
	layer = 100
	
	# 1. Standard string-based request (for generic messages)
	SignalBus.request_floating_text.connect(_on_floating_text_requested)
	
	# 2. Resource-based requests (for +50⚡ or -$10)
	# You'll need to add this signal to your SignalBus: 
	# signal request_resource_text(pos: Vector2, type: int, amount: float, is_currency: bool)
	if SignalBus.has_signal("request_resource_text"):
		SignalBus.request_resource_text.connect(_on_resource_text_requested)

# ==============================================================================
# 1. RESOURCE-AWARE HANDLER
# ==============================================================================
func _on_resource_text_requested(pos: Vector2, type: int, amount: float, is_currency: bool) -> void:
	var def = null
	
	if is_currency:
		def = CurrencyManager.get_definition(type)
	else:
		def = VitalManager.get_definition(type)
		
	if not def: return
	
	# Prepare the icon and color from the resource definition
	var icon = def.text_icon
	var color = def.display_color
	
	var prefix = "+" if amount > 0 else "-"
	var amount_str = str(abs(int(amount))) # abs() makes -50 into 50
	
	# Combine into a single string for the floating text instance
	var final_text = ""
	if is_currency:
		# Output: -$50
		final_text = "%s%s%s" % [prefix, icon, amount_str]
	else:
		# Output: -50 ⚡
		final_text = "%s%s %s" % [prefix, amount_str, icon]
	
	_on_floating_text_requested(pos, final_text, color)

# ==============================================================================
# 2. BASE HANDLER
# ==============================================================================
func _on_floating_text_requested(pos: Vector2, text: String, color: Color) -> void:
	if not floating_text_scene: return
	
	var txt = floating_text_scene.instantiate()
	add_child(txt)
	
	if txt.has_method("animate"):
		txt.animate(pos, text, color)
