extends Button
class_name ItemInfoButton

var info_title: String = ""
var info_desc: String = ""

func _ready() -> void:
	pressed.connect(_on_pressed)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	focus_mode = Control.FOCUS_NONE

# Added an optional 'source' parameter that defaults to null
func setup(t: String, d: String, source: Resource = null) -> void:
	info_title = t
	info_desc = d
	visible = info_desc != ""
	
	# --- THE DEVELOPER WARNING ---
	if info_desc == "":
		# If the source is one of our exceptions, quietly skip the warning
		if source is CurrencyDefinition or source is StatDefinition or source is VitalDefinition:
			return 
			
		push_warning("ItemInfoButton hidden: '%s' has no description text!" % info_title)

func _on_pressed() -> void:
	SignalBus.show_info_requested.emit(info_title, info_desc)
