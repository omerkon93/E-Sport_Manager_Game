extends Node

# --- SIGNALS ---
signal game_loaded # New signal to tell the UI to reload the scene

# --- CONFIGURATION ---
const AUTO_SAVE_INTERVAL = 30.0 

var _timer: Timer
var current_slot_id: int = 1 # Default to Slot 1

# ==============================================================================
# LIFECYCLE
# ==============================================================================
func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = AUTO_SAVE_INTERVAL
	_timer.one_shot = false
	# Don't auto-start. We wait until a game actually starts/loads.
	_timer.autostart = false 
	_timer.timeout.connect(save_game)
	add_child(_timer)

# ==============================================================================
# SAVE / LOAD LOGIC
# ==============================================================================
func save_game() -> void:
	print("Saving game to Slot ", current_slot_id, "...")
		
	var save_data = {
		"version": "1.1",
		"timestamp": Time.get_unix_time_from_system(),
		"currency": CurrencyManager.get_save_data(),
		"team": GameManager.get_save_data(),
		"market": MarketManager.get_save_data(),
		"settings": SettingsManager.get_save_data(),
		"progression": ProgressionManager.get_save_data(),
		"research": ResearchManager.get_save_data() if ResearchManager else {},
	}
	
	var path = get_save_path(current_slot_id)
	var file = FileAccess.open(path, FileAccess.WRITE)
	
	if file:
		var json_text = JSON.stringify(save_data, "\t")
		file.store_string(json_text)
		file.close()

func load_game(slot_id: int = -1, send_signal: bool = true) -> void:
	if slot_id != -1:
		current_slot_id = slot_id

	var path = get_save_path(current_slot_id)
	
	if not FileAccess.file_exists(path):
		print("No save file found for Slot ", current_slot_id)
		return
	
	var file = FileAccess.open(path, FileAccess.READ)
	var text = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(text)
	
	if error == OK:
		var data = json.data
		print("Loading save from Slot ", current_slot_id, "...")
		
		if data.has("currency"): CurrencyManager.load_save_data(data.currency)
		if data.has("team"): GameManager.load_save_data(data.team)
		if data.has("market"): MarketManager.load_save_data(data.market)
		if data.has("settings"): SettingsManager.load_save_data(data.settings)
		if data.has("progression"): ProgressionManager.load_save_data(data.progression)
		if data.has("research") and ResearchManager: ResearchManager.load_save_data(data.research)
		if data.has("time") and TimeManager and TimeManager.has_method("load_save_data"): TimeManager.load_save_data(data.time)
		
		print("✅ Game Loaded Successfully!")
		
		_timer.start()
		
		if send_signal:
			game_loaded.emit()
		
	else:
		print("JSON Parse Error: ", json.get_error_message())

# ==============================================================================
# SLOT MANAGEMENT
# ==============================================================================
# Generates the path based on the Slot ID (e.g., "save_game_1.json")
func get_save_path(slot_id: int) -> String:
	return "user://save_game_" + str(slot_id) + ".json"

# Call this when starting a FRESH game to ensure the timer starts
func start_new_game(slot_id: int) -> void:
	current_slot_id = slot_id
	print("Starting new game on Slot ", slot_id)
	
	if save_file_exists(slot_id):
		delete_save(slot_id)
		
	# --- Wipe ALL Managers clean for the new game ---
	if ProgressionManager.has_method("reset"): ProgressionManager.reset()
	if QuestManager.has_method("reset"): QuestManager.reset()
	
	# NEW RESETS
	if ResearchManager and ResearchManager.has_method("reset"): ResearchManager.reset()
	if CurrencyManager and CurrencyManager.has_method("reset"): CurrencyManager.reset()
	if VitalManager and VitalManager.has_method("reset"): VitalManager.reset()
	if TimeManager and TimeManager.has_method("reset"): TimeManager.reset()
	if SubscriptionManager and SubscriptionManager.has_method("reset"): SubscriptionManager.reset()
		
	_timer.start()

func delete_save(slot_id: int) -> void:
	var path = get_save_path(slot_id)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		print("Save slot ", slot_id, " deleted.")

func save_file_exists(slot_id: int) -> bool:
	return FileAccess.file_exists(get_save_path(slot_id))

# Returns metadata for the save slot selection menu
func get_slot_metadata(slot_id: int) -> Dictionary:
	var path = get_save_path(slot_id)
	
	if not FileAccess.file_exists(path):
		return { "exists": false, "timestamp": "" }
	
	var file = FileAccess.open(path, FileAccess.READ)
	var text = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(text)
	
	if error == OK:
		var data = json.data
		var time_str = ""
		
		if data.has("timestamp"):
			var time_dict = Time.get_datetime_dict_from_unix_time(int(data.timestamp))
			time_str = "%04d-%02d-%02d %02d:%02d" % [time_dict.year, time_dict.month, time_dict.day, time_dict.hour, time_dict.minute]
			
		return { "exists": true, "timestamp": time_str }
		
	return { "exists": false, "timestamp": "Corrupted" }
