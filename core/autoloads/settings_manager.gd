extends Node

# Signal to tell the UI to update immediately when a setting changes
signal setting_changed(key: String, value: Variant)

const SETTINGS_PATH = "user://global_settings.json"

# Default Settings
var _settings: Dictionary = {
	"time_format_24h": true,  # true = 24h (14:00), false = 12h (2:00 PM)
	"master_volume": 1.0,
	"music_volume": 1.0,
	"sfx_volume": 1.0
}

# ==============================================================================
# LIFECYCLE
# ==============================================================================
func _ready() -> void:
	# Load global settings the exact moment the game boots up
	load_settings()

# ==============================================================================
# GETTERS / SETTERS
# ==============================================================================
func get_setting(key: String, default_val: Variant = null) -> Variant:
	return _settings.get(key, default_val)

func set_setting(key: String, value: Variant) -> void:
	_settings[key] = value
	setting_changed.emit(key, value)
	
	# Automatically save to disk every time the player tweaks a slider or toggle
	save_settings()

# ==============================================================================
# INDEPENDENT SAVE / LOAD
# ==============================================================================
func save_settings() -> void:
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		# Write the dictionary directly to its own independent file
		file.store_string(JSON.stringify(_settings, "\t"))
		file.close()
		print("⚙️ Global settings saved.")

func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		print("⚙️ No global settings found. Using defaults.")
		return
		
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	
	if error == OK:
		var data = json.data
		for key in data:
			_settings[key] = data[key]
			# Emit the signal so UI elements snap to the correct values
			setting_changed.emit(key, data[key])
		print("⚙️ Global settings loaded.")
	else:
		push_error("⚙️ Error parsing global settings: ", json.get_error_message())
