@tool
extends EditorScript

# This function runs when we trigger the script in the editor!
func _run() -> void:
	print("🛠️ Starting Bulk Weapon Generation...")
	
	# 1. Define your master list of weapons here (or you could load a JSON/CSV file!)
	var weapon_database = {
		"AWP": {"fire_rate": 1.5, "accuracy": 1.3, "mobility": 0.6},
		"MAC-10": {"fire_rate": 0.1, "accuracy": 0.6, "mobility": 1.1},
		"M4A4": {"fire_rate": 0.25, "accuracy": 1.05, "mobility": 0.95},
		"AK-47": {"fire_rate": 0.3, "accuracy": 1.0, "mobility": 0.95},
		"DESERT_EAGLE": {"fire_rate": 0.45, "accuracy": 1.1, "mobility": 1.0}
	}
	
	var save_path = "res://game_data/weapons/"
	
	# 2. Make sure the folder exists so Godot doesn't crash
	if not DirAccess.dir_exists_absolute(save_path):
		DirAccess.make_dir_absolute(save_path)
	
	# 3. Loop through the dictionary, create the Resource, and save it!
	for w_name in weapon_database.keys():
		var stats = weapon_database[w_name]
		
		# Create a blank instance of your Custom Resource
		var new_weapon = WeaponData.new()
		
		# Inject the data
		new_weapon.weapon_name = w_name
		new_weapon.fire_rate = stats["fire_rate"]
		new_weapon.accuracy_multiplier = stats["accuracy"]
		new_weapon.mobility = stats["mobility"]
		
		# Format the file name (e.g., "ak-47.tres")
		var file_name = w_name.to_lower().replace(" ", "_") + ".tres"
		var full_path = save_path + file_name
		
		# Tell Godot to physically save the file to your hard drive
		var error = ResourceSaver.save(new_weapon, full_path)
		
		if error == OK:
			print("✅ Generated: ", file_name)
		else:
			push_error("❌ Failed to save: ", file_name)
			
	print("🎉 Bulk Generation Complete!")
