extends Node

# ==============================================================================
# SIGNALS
# ==============================================================================
# Emitted whenever a vital changes value (for UI bars/text)
signal vital_changed(type: VitalDefinition.VitalType, current: float, max_val: float)

# Emitted specifically when a vital hits 0 (for Game Over or Debuffs)
signal vital_depleted(type: VitalDefinition.VitalType) 


# ==============================================================================
# DATA STORAGE
# ==============================================================================
# Dynamic State: Stores the current numbers.
# Format: { VitalDefinition.VitalType : { "current": 50.0, "max": 100.0 } }
var _vitals: Dictionary = {}

# Static Config: Stores the resource files (Icon, Name, Color).
# Format: { VitalDefinition.VitalType : VitalDefinition }
var _definitions: Dictionary = {}


# ==============================================================================
# LIFECYCLE & INITIALIZATION
# ==============================================================================
func _ready() -> void:
	# Fallback initialization if definitions aren't loaded externally
	# (You can remove this if you call initialize_vitals from a Bootstrap script)
	_init_fallback_vital(VitalDefinition.VitalType.ENERGY, 100.0)
	_init_fallback_vital(VitalDefinition.VitalType.FULLNESS, 100.0)
	_init_fallback_vital(VitalDefinition.VitalType.FOCUS, 100.0)
	_init_fallback_vital(VitalDefinition.VitalType.SANITY, 100.0)

func initialize_vitals(vitals: Array[VitalDefinition]) -> void:
	for v in vitals:
		_definitions[v.type] = v
		# If not already created by save data or fallback, init here
		if not _vitals.has(v.type):
			_init_fallback_vital(v.type, v.default_max_value)

func _init_fallback_vital(type: int, default_max: float) -> void:
	_vitals[type] = {
		"current": default_max,
		"max": default_max
	}

# ==============================================================================
# PUBLIC API: GETTERS
# ==============================================================================
func get_current(type: int) -> float:
	if not type in _vitals: return 0.0
	return _vitals[type]["current"]

func get_max(type: int) -> float:
	if not type in _vitals: return 100.0
	return _vitals[type]["max"]

func has_enough(type: int, amount: float) -> bool:
	return get_current(type) >= amount

# Retrieves the static Resource file (for UI Icons/Colors)
func get_definition(type: VitalDefinition.VitalType) -> VitalDefinition:
	if _definitions.has(type):
		return _definitions[type]
	
	# DEBUG: Print warning but don't crash
	push_warning("Vital Definition missing for ID %s. Have you called initialize_vitals()?" % type)
	
	# Return a dummy or null to prevent the crash
	return null

func get_vital_value(vital_type: int) -> float:
	return get_current(vital_type)

# ==============================================================================
# PUBLIC API: MODIFIERS
# ==============================================================================
# The core logic for changing values. Handles clamping and signals.
func change_vital(type: int, amount: float) -> void:
	if not type in _vitals: return
	
	var data = _vitals[type]
	var old_value: float = data["current"]
	
	# Apply change and clamp between 0 and Max
	data["current"] = clampf(data["current"] + amount, 0.0, data["max"])
	var new_value: float = data["current"]
	
	# Optimization: Only update UI if the number actually changed
	if old_value != new_value:
		vital_changed.emit(type, new_value, data["max"])
	
	# Logic: Only trigger depletion if we transitioned FROM >0 TO <=0
	if new_value <= 0.0 and old_value > 0.0:
		vital_depleted.emit(type)

# Helper to remove resources safely
func consume(type: int, amount: float) -> bool:
	if has_enough(type, amount):
		change_vital(type, -amount)
		return true
	return false

# Helper to add resources
func restore(type: int, amount: float) -> void:
	change_vital(type, amount)

# Used primarily by the Save System to force a specific state
func set_vital(type: int, amount: float) -> void:
	if not type in _vitals: return
	
	var data = _vitals[type]
	
	# Clamp ensures we don't load corrupted/negative data
	data["current"] = clampf(amount, 0.0, data["max"])
	
	# Force an update so the UI syncs immediately
	vital_changed.emit(type, data["current"], data["max"])


# ==============================================================================
# PERSISTENCE (SAVE / LOAD)
# ==============================================================================
func get_save_data() -> Dictionary:
	var save_data = {}
	
	for id in _vitals:
		# JSON requires string keys.
		# We only save 'current'. 'max' is derived from upgrades/definitions.
		save_data[str(id)] = _vitals[id]["current"]
		
	return save_data

func load_save_data(data: Dictionary) -> void:
	for id_str in data:
		var id = int(id_str) # Convert JSON string back to Enum Int
		var value = data[id_str]
		
		if _vitals.has(id):
			set_vital(id, value)

# ==============================================================================
# RESET LOGIC
# ==============================================================================
func reset() -> void:
	for type in _vitals:
		var data = _vitals[type]
		# Restore current to whatever the max is
		data["current"] = data["max"]
		# Tell the UI to update the bars back to 100%
		vital_changed.emit(type, data["current"], data["max"])
	
	print("❤️ VitalManager: Reset all vitals to max.")
