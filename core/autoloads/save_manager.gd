extends Node

const AUTO_SAVE_INTERVAL = 30.0 
var _timer: Timer
var current_slot_id: int = 1

func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = AUTO_SAVE_INTERVAL
	_timer.autostart = false 
	_timer.timeout.connect(save_game)
	add_child(_timer)

# ==============================================================================
# DECOUPLED SAVE / LOAD
# ==============================================================================
func save_game() -> void:
	print("Saving game to Slot ", current_slot_id, "...")
		
	var save_data = {
		"version": "1.1",
		"timestamp": Time.get_unix_time_from_system(),
		"systems": {} # We will stuff all manager data in here dynamically!
	}
	
	# Ask every node in the "persist" group for its save data!
	var save_nodes = get_tree().get_nodes_in_group("persist")
	for node in save_nodes:
		if node.has_method("get_save_data"):
			# Use the node's name as the dictionary key
			save_data["systems"][node.name] = node.get_save_data()
	
	var path = get_save_path(current_slot_id)
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()

func load_game(slot_id: int = -1, send_signal: bool = true) -> void:
	if slot_id != -1: current_slot_id = slot_id

	var path = get_save_path(current_slot_id)
	if not FileAccess.file_exists(path): return
	
	var file = FileAccess.open(path, FileAccess.READ)
	var json = JSON.new()
	
	if json.parse(file.get_as_text()) == OK:
		var data = json.data
		
		# Distribute the loaded data dynamically!
		if data.has("systems"):
			var save_nodes = get_tree().get_nodes_in_group("persist")
			for node in save_nodes:
				if node.has_method("load_save_data") and data["systems"].has(node.name):
					node.load_save_data(data["systems"][node.name])
		
		print("✅ Game Loaded Successfully!")
		_timer.start()
		
		if send_signal:
			SignalBus.game_loaded.emit() # Make sure this signal is declared in SignalBus!

func start_new_game(slot_id: int) -> void:
	current_slot_id = slot_id
	
	if save_file_exists(slot_id):
		delete_save(slot_id)
		
	# Dynamically reset any manager that has a reset function!
	var save_nodes = get_tree().get_nodes_in_group("persist")
	for node in save_nodes:
		if node.has_method("reset"):
			node.reset()
			
	_timer.start()

# ==============================================================================
# HELPER FUNCTIONS (Restored)
# ==============================================================================
func get_save_path(slot_id: int) -> String:
	return "user://save_game_" + str(slot_id) + ".json"

func save_file_exists(slot_id: int) -> bool:
	return FileAccess.file_exists(get_save_path(slot_id))

func delete_save(slot_id: int) -> void:
	var path = get_save_path(slot_id)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		print("Save slot ", slot_id, " deleted.")

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
