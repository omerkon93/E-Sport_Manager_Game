@tool
extends EditorScript

# This function runs when we trigger the script in the editor!
func _run() -> void:
	print("🛠️ Starting Bulk Weapon Generation...")
	
	# 1. Define your master list of weapons here (or you could load a JSON/CSV file!)
	var weapon_database = {
		# --- SNIPERS ---
		"AWP": {"name": "AWP", "fire_rate": 0.2, "damage": 115, "accuracy": 1.0, "mobility": 0.5, "cost": 4750},
		"SSG_08": {"name": "SSG 08", "fire_rate": 0.4, "damage": 88, "accuracy": 0.9, "mobility": 0.85, "cost": 900},

		# --- RIFLES ---
		"AK-47": {"name": "AK-47", "fire_rate": 1.5, "damage": 36, "accuracy": 0.75, "mobility": 0.7, "cost": 2700},
		"M4A4": {"name": "M4A4", "fire_rate": 1.7, "damage": 30, "accuracy": 0.85, "mobility": 0.75, "cost": 3000},
		"M4A1-S": {"name": "M4A1-S", "fire_rate": 1.5, "damage": 32, "accuracy": 0.95, "mobility": 0.75, "cost": 2900},
		"GALIL_AR": {"name": "Galil AR", "fire_rate": 1.7, "damage": 30, "accuracy": 0.65, "mobility": 0.72, "cost": 1800},
		"FAMAS": {"name": "FAMAS", "fire_rate": 1.7, "damage": 30, "accuracy": 0.7, "mobility": 0.72, "cost": 2050},
		"AUG": {"name": "AUG", "fire_rate": 1.7, "damage": 28, "accuracy": 0.9, "mobility": 0.65, "cost": 3300},
		"SG_553": {"name": "SG 553", "fire_rate": 1.5, "damage": 30, "accuracy": 0.8, "mobility": 0.62, "cost": 3000},

		# --- SUBMACHINE GUNS ---
		"MAC-10": {"name": "MAC-10", "fire_rate": 2.2, "damage": 29, "accuracy": 0.4, "mobility": 0.95, "cost": 1050},
		"MP9": {"name": "MP9", "fire_rate": 2.4, "damage": 26, "accuracy": 0.45, "mobility": 0.95, "cost": 1250},
		"UMP-45": {"name": "UMP-45", "fire_rate": 1.4, "damage": 35, "accuracy": 0.55, "mobility": 0.88, "cost": 1200},
		"P90": {"name": "P90", "fire_rate": 2.4, "damage": 26, "accuracy": 0.5, "mobility": 0.9, "cost": 2350},
		"MP7": {"name": "MP7", "fire_rate": 1.8, "damage": 29, "accuracy": 0.6, "mobility": 0.85, "cost": 1500},

		# --- PISTOLS ---
		"DESERT_EAGLE": {"name": "Desert Eagle", "fire_rate": 0.8, "damage": 63, "accuracy": 0.8, "mobility": 0.82, "cost": 700},
		"GLOCK": {"name": "Glock-18", "fire_rate": 1.2, "damage": 28, "accuracy": 0.5, "mobility": 0.95, "cost": 200},
		"USP-S": {"name": "USP-S", "fire_rate": 1.2, "damage": 35, "accuracy": 0.9, "mobility": 0.95, "cost": 200},
		"P250": {"name": "P250", "fire_rate": 1.3, "damage": 38, "accuracy": 0.6, "mobility": 0.95, "cost": 300},
		"TEC-9": {"name": "Tec-9", "fire_rate": 1.5, "damage": 33, "accuracy": 0.55, "mobility": 0.98, "cost": 500},
		"FIVE_SEVEN": {"name": "Five-SeveN", "fire_rate": 1.3, "damage": 32, "accuracy": 0.85, "mobility": 0.95, "cost": 500},

		# --- HEAVY ---
		"MAG-7": {"name": "MAG-7", "fire_rate": 0.5, "damage": 120, "accuracy": 0.3, "mobility": 0.75, "cost": 1300},
		"XM1014": {"name": "XM1014", "fire_rate": 1.1, "damage": 100, "accuracy": 0.25, "mobility": 0.7, "cost": 2000},
		"NEGEV": {"name": "Negev", "fire_rate": 3.0, "damage": 35, "accuracy": 0.2, "mobility": 0.4, "cost": 1700}
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
		new_weapon.weapon_name =  stats["name"]
		new_weapon.base_damage = stats["damage"]
		new_weapon.fire_rate = stats["fire_rate"]
		new_weapon.accuracy_multiplier = stats["accuracy"]
		new_weapon.mobility = stats["mobility"]
		new_weapon.cost = stats["cost"]
		
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
