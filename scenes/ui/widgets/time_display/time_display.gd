extends PanelContainer
class_name TimeDisplay

# --- NODES ---
# We use the same structure as ResourceDisplay so you can reuse the prefab
@onready var icon_rect: TextureRect = %Icon
@onready var value_label: Label = %ValueLabel
@onready var progress_bar: ProgressBar = %ProgressBar

# Optional: Export an icon for the clock
@export var clock_icon: Texture2D
@export var text_icon: String = "🕒"

func _ready() -> void:
	# 1. Setup Visuals
	if clock_icon:
		icon_rect.texture = clock_icon
	
	if progress_bar:
		progress_bar.visible = false
		
	# 2. Connect to TimeManager (Updates every game minute)
	TimeManager.time_updated.connect(_on_time_updated)
	
	# 3. Connect to SettingsManager (Updates instantly when you toggle the checkbox)
	SettingsManager.setting_changed.connect(_on_setting_changed)
	
	# 4. Initial Display
	_update_display()

func _on_time_updated(_day: int, _hour: int, _minute: int) -> void:
	_update_display()

# New: Handle setting changes
func _on_setting_changed(key: String, _value: Variant) -> void:
	if key == "time_format_24h":
		_update_display()

func _update_display() -> void:
	var day = TimeManager.current_day
	var hour = TimeManager.current_hour
	var minute = TimeManager.current_minute
	var is_24h = SettingsManager.get_setting("time_format_24h", true)
	
	var time_str = ""
	
	if is_24h:
		time_str = "%02d:%02d" % [hour, minute]
	else:
		var suffix = "AM"
		var display_hour = hour
		if hour >= 12:
			suffix = "PM"
			if hour > 12: display_hour -= 12
		elif hour == 0:
			display_hour = 12
		time_str = "%d:%02d %s" % [display_hour, minute, suffix]
	
	# Added the text_icon here to match your ResourceDisplay style
	var day_str = "%s Day %d" % [text_icon, day]
	value_label.text = "%s | %s" % [day_str, time_str]
