extends Node

# --- SIGNALS ---
signal quest_activated(quest_data: QuestData)
# Updated signal to pass the specific action that was updated
signal quest_progress_updated(quest_id: String, action_id: String, current: int, required: int)
signal quest_completed(quest_data: QuestData)

# --- CONFIGURATION ---
const QUESTS_PATH = "res://game_data/game_progression/quests/"

# --- STATE ---
# active_quests now stores: quest_id (String) -> Dictionary of action progress { action_id: current_amount }
var active_quests: Dictionary = {} 
var completed_quests: Dictionary = {}

# --- DATABASE ---
var all_quests: Array[QuestData] = []

# ==============================================================================
# LIFECYCLE (Unchanged)
# ==============================================================================
# In QuestManager.gd _ready():
func _ready() -> void:
	_load_quests()
	SignalBus.action_performed.connect(_on_action_triggered)
	SignalBus.story_flag_changed.connect(_on_flag_changed)
	SignalBus.game_time_day_started.connect(_on_day_started)

func reset() -> void:
	active_quests.clear()
	completed_quests.clear()
	_evaluate_all_quests()

func _load_quests() -> void:
	var files = _get_all_files_recursive(QUESTS_PATH)
	for file_path in files:
		if file_path.ends_with(".tres") or file_path.ends_with(".res"):
			var res = load(file_path)
			if res is QuestData:
				all_quests.append(res)
	print("📜 QuestManager: Loaded %d quests." % all_quests.size())

func _get_all_files_recursive(path: String) -> Array[String]:
	var file_paths: Array[String] = []
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				if file_name != "." and file_name != "..":
					file_paths.append_array(_get_all_files_recursive(path + "/" + file_name))
			else:
				file_paths.append(path + "/" + file_name)
			file_name = dir.get_next()
	return file_paths

# ==============================================================================
# EVENT LISTENERS
# ==============================================================================
func _on_flag_changed(flag_id: String, value: bool) -> void:
	if not value: return
	
	# 1. Check if this unlocks NEW quests
	for quest in all_quests:
		for req_flag in quest.required_story_flags:
			if req_flag and req_flag.id == flag_id:
				if _can_activate_quest(quest):
					_activate_quest(quest)
				break
			
	# 2. Check if this completes ACTIVE quests
	var current_active_keys = active_quests.keys()
	for quest_id in current_active_keys:
		var quest = _get_quest_data(quest_id)
		if quest:
			_check_quest_completion(quest)

func _on_action_triggered(action_data: ActionData) -> void:
	if not action_data: return
	
	for quest_id in active_quests.keys():
		var quest = _get_quest_data(quest_id)
		if not quest: continue
		
		# Check if the triggered action is a target for this quest
		for target_action in quest.target_actions.keys():
			if target_action is ActionData and target_action.id == action_data.id:
				_increment_quest_progress(quest, target_action)

func _on_day_started(_day: int) -> void:
	var current_active_keys = active_quests.keys()
	for quest_id in current_active_keys:
		var quest = _get_quest_data(quest_id)
		if quest and quest.reset_on_new_day:
			_reset_quest_progress(quest)

func _reset_quest_progress(quest: QuestData) -> void:
	var progress_dict = active_quests[quest.id]
	var progress_was_lost = false
	
	# Loop through every action this quest tracks
	for action in quest.target_actions:
		var current = progress_dict.get(action.id, 0)
		
		# If they had progress > 0, we need to wipe it
		if current > 0:
			progress_dict[action.id] = 0
			progress_was_lost = true
			
			var required = quest.target_actions[action]
			# Emit the signal so the QuestItemUI progress bar drops back to 0!
			quest_progress_updated.emit(quest.id, action.id, 0, required)
			
	# Optional: Give the player a UI notification so they understand what happened
	if progress_was_lost and SignalBus.has_signal("message_logged"):
		SignalBus.message_logged.emit("Daily target failed: " + quest.title + " (Progress Reset)", Color.ORANGE)

# ==============================================================================
# CORE LOGIC
# ==============================================================================
func _activate_quest(quest: QuestData) -> void:
	if active_quests.has(quest.id) or completed_quests.has(quest.id): return
	
	# Initialize progress dictionary for this quest
	var progress_dict = {}
	for action in quest.target_actions.keys():
		if action is ActionData:
			progress_dict[action.id] = 0
			
	active_quests[quest.id] = progress_dict
	quest_activated.emit(quest)
	print("📜 New Quest Activated: ", quest.title)
	
	_check_quest_completion(quest)

func _increment_quest_progress(quest: QuestData, action: ActionData) -> void:
	var progress = active_quests[quest.id]
	progress[action.id] += 1
	
	var required = quest.target_actions[action]
	quest_progress_updated.emit(quest.id, action.id, progress[action.id], required)
	
	_check_quest_completion(quest)

func _check_quest_completion(quest: QuestData) -> void:
	# 1. Check Target Story Flags
	for flag in quest.target_story_flags:
		if flag and not ProgressionManager.get_flag(flag.id):
			return 
			
	# 2. Check Target Actions
	var progress = active_quests[quest.id]
	for action in quest.target_actions:
		var required = quest.target_actions[action]
		var current = progress.get(action.id, 0)
		
		if current < required:
			return # Missing an action requirement, exit early
				
	# If we survived both loops, the quest is done!
	_complete_quest(quest)

# In QuestManager.gd _complete_quest():
func _complete_quest(quest: QuestData) -> void:
	active_quests.erase(quest.id)
	completed_quests[quest.id] = true
	
	print("✅ Quest Completed: ", quest.title)
	
	quest_completed.emit(quest)

# ==============================================================================
# HELPERS & SAVE DATA
# ==============================================================================
func _can_activate_quest(quest: QuestData) -> bool:
	if active_quests.has(quest.id) or completed_quests.has(quest.id): return false
	for flag in quest.required_story_flags:
		if flag and not ProgressionManager.get_flag(flag.id): return false
	for prereq in quest.prerequisite_quests:
		if prereq and not completed_quests.has(prereq.id): return false
	return true

func _get_quest_data(id: String) -> QuestData:
	for q in all_quests:
		if q.id == id: return q
	return null

func get_save_data() -> Dictionary:
	return { "active": active_quests.duplicate(true), "completed": completed_quests.duplicate(true) }

func load_save_data(data: Dictionary) -> void:
	active_quests = data.get("active", {})
	completed_quests = data.get("completed", {})
	_evaluate_all_quests()

func _evaluate_all_quests() -> void:
	for quest in all_quests:
		if _can_activate_quest(quest):
			_activate_quest(quest)
