extends Node

# --- CONFIGURATION ---
# The folder where all your ActionData resources are stored
const AUTO_LOAD_PATHS = [
	"res://game_data/actions/player_actions/"
]

# --- SIGNALS ---
@warning_ignore("unused_signal")
signal action_triggered(action_data: ActionData)

# --- STATE ---
# The master list used by the ActionsMenu to populate the UI
var all_actions: Array[ActionData] = []

# ==============================================================================
# 1. LIFECYCLE
# ==============================================================================
func _ready() -> void:
	# Run the scanner as soon as the manager enters the tree
	_scan_for_actions()


# ==============================================================================
# 2. AUTO-LOADER LOGIC
# ==============================================================================
func _scan_for_actions() -> void:
	for path in AUTO_LOAD_PATHS:
		_load_dir_recursive(path)
	
	print("🎬 ActionManager: Automatically loaded %d actions." % all_actions.size())

func _load_dir_recursive(path: String) -> void:
	
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if dir.current_is_dir():
				# Dive into subfolders (e.g., res://game_data/actions/career/)
				if file_name != "." and file_name != "..":
					_load_dir_recursive(path + "/" + file_name)
			else:
				# Only load valid Godot resource files
				if file_name.ends_with(".tres") or file_name.ends_with(".res"):
					var full_path = path + "/" + file_name
					var resource = load(full_path)
					
					# Ensure the file is actually an ActionData resource
					if resource is ActionData:
						_add_action(resource)
			
			file_name = dir.get_next()
	else:
		print("❌ ActionManager Error: Could not open path: ", path)

func _add_action(action: ActionData) -> void:
	# Check for duplicates
	if not all_actions.any(func(x): return x.id == action.id):
		all_actions.append(action)
	else:
		# ADD THIS WARNING!
		push_warning("⚠️ ActionManager: Duplicate Action ID found! Skipped '%s' (ID: %s)" % [action.resource_path, action.id])


# ==============================================================================
# 3. PUBLIC API
# ==============================================================================
# ==============================================================================
# 3. PUBLIC API
# ==============================================================================
func get_action_by_id(id: String) -> ActionData:
	for action in all_actions:
		if action.id == id:
			return action
	return null

func is_action_unlocked(action: ActionData) -> bool:
	var has_locks = false
	
	# 1. Check Story Flag Lock
	if action.required_story_flag != null:
		has_locks = true
		if not ProgressionManager.get_flag(action.required_story_flag.id):
			return false # Failed the flag requirement

	# 2. Check Quest Lock (Currently set up as AND logic: must complete ALL listed quests)
	if action.required_completed_quests.size() > 0:
		has_locks = true
		for quest in action.required_completed_quests:
			if quest and not QuestManager.completed_quests.has(quest.id):
				return false # Failed the quest requirement

	# 3. The Final Verdict
	if has_locks:
		# If the action HAD locks, and we survived the checks above without returning false,
		# it means the player satisfied every single requirement!
		return true
		
	# If the action has NO locks attached to it at all, we just look at the checkbox.
	return action.is_unlocked_by_default

# ==============================================================================
# 4. ACTION EXECUTION & MATH
# ==============================================================================
func try_perform_action(action: ActionData) -> bool:
	# 1. GET EFFICIENCY DISCOUNT (Calculated locally by ActionData!)
	var cost_multiplier = action.energy_cost_multiplier

	# 2. VALIDATION (Can we afford it?)
	for vit_type in action.vital_costs:
		var final_cost = action.vital_costs[vit_type] * cost_multiplier
		if not VitalManager.has_enough(vit_type, final_cost):
			return false
			
	for cur_type in action.currency_costs:
		var amount = action.currency_costs[cur_type]
		if not CurrencyManager.has_enough_currency(cur_type, amount):
			return false

	# 3. CONSUME COSTS
	for vit_type in action.vital_costs:
		var final_cost = action.vital_costs[vit_type] * cost_multiplier
		VitalManager.consume(vit_type, final_cost)
		
	for cur_type in action.currency_costs:
		var amount = action.currency_costs[cur_type]
		CurrencyManager.spend_currency(cur_type, amount)

	# 4. APPLY REWARDS (Gains)
	for vit_type in action.vital_gains:
		VitalManager.restore(vit_type, action.vital_gains[vit_type])
		
	for cur_type in action.currency_gains:
		CurrencyManager.add_currency(cur_type, action.currency_gains[cur_type])
		
	# 5. TIME COSTS
	if "effective_time_cost" in action and action.effective_time_cost > 0:
		var time_mgr = get_tree().root.get_node_or_null("TimeManager")
		if time_mgr and time_mgr.has_method("add_minutes"):
			time_mgr.add_minutes(action.effective_time_cost)

	return true
