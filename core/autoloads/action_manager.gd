extends Node

# --- CONFIGURATION ---
const AUTO_LOAD_PATHS = [
	"res://game_data/actions/player_actions/"
]

# --- SIGNALS ---
@warning_ignore("unused_signal")
signal action_triggered(action_data: ActionData)

# --- STATE ---
var all_actions: Array[ActionData] = []

# ==============================================================================
# 1. LIFECYCLE
# ==============================================================================
func _ready():
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
				if file_name != "." and file_name != "..":
					_load_dir_recursive(path + "/" + file_name)
			else:
				if file_name.ends_with(".tres") or file_name.ends_with(".res"):
					var full_path = path + "/" + file_name
					var resource = load(full_path)
					if resource is ActionData:
						_add_action(resource)
			file_name = dir.get_next()
	else:
		print("❌ ActionManager Error: Could not open path: ", path)

func _add_action(action: ActionData) -> void:
	if not all_actions.any(func(x): return x.id == action.id):
		all_actions.append(action)
	else:
		push_warning("⚠️ ActionManager: Duplicate Action ID found! Skipped '%s' (ID: %s)" % [action.resource_path, action.id])

# ==============================================================================
# 3. PUBLIC API (Database Queries Only)
# ==============================================================================
func get_action_by_id(id: String) -> ActionData:
	for action in all_actions:
		if action.id == id:
			return action
	return null

func is_action_unlocked(action: ActionData) -> bool:
	var has_locks = false
	
	if action.required_story_flag != null:
		has_locks = true
		if not ProgressionManager.get_flag(action.required_story_flag.id):
			return false

	if action.required_completed_quests.size() > 0:
		has_locks = true
		for quest in action.required_completed_quests:
			if quest and not QuestManager.completed_quests.has(quest.id):
				return false

	if has_locks:
		return true
		
	return action.is_unlocked_by_default
