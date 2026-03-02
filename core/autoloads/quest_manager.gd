extends Node

# --- SIGNALS ---
signal quest_activated(quest_data: QuestData)
signal quest_progress_updated(quest_id: String, current: int, required: int)
signal quest_completed(quest_data: QuestData)

# --- CONFIGURATION ---
const QUESTS_PATH = "res://game_data/game_progression/quests/"

# --- STATE ---
# Dictionary of quest_id (String) -> current_progress (int)
var active_quests: Dictionary = {} 
# Dictionary of quest_id (String) -> true (bool)
var completed_quests: Dictionary = {}

# --- DATABASE ---
var all_quests: Array[QuestData] = []

# ==============================================================================
# LIFECYCLE
# ==============================================================================
func _ready() -> void:
	_load_quests()
	
	# Listen for actions being clicked
	if SignalBus.has_signal("action_triggered"):
		SignalBus.action_triggered.connect(_on_action_triggered)
		
	# Listen for story flags to unlock new quests
	if ProgressionManager.has_signal("flag_changed"):
		ProgressionManager.flag_changed.connect(_on_flag_changed)

func reset() -> void:
	active_quests.clear()
	completed_quests.clear()
	_evaluate_all_quests()

func _load_quests() -> void:
	var dir = DirAccess.open(QUESTS_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and (file_name.ends_with(".tres") or file_name.ends_with(".res")):
				var res = load(QUESTS_PATH + "/" + file_name)
				if res is QuestData:
					all_quests.append(res)
			file_name = dir.get_next()
		print("📜 QuestManager: Loaded %d quests." % all_quests.size())

# ==============================================================================
# EVENT LISTENERS
# ==============================================================================
func _on_flag_changed(flag_id: String, value: bool) -> void:
	if not value: return
	
	# 1. Check if this flag unlocks any NEW quests
	for quest in all_quests:
		if quest.required_story_flag and quest.required_story_flag.id == flag_id:
			_activate_quest(quest)
			
	# 2. NEW: Check if this flag completes an objective for ACTIVE quests
	var current_active_keys = active_quests.keys()
	for quest_id in current_active_keys:
		var quest = _get_quest_data(quest_id)
		
		if quest and quest.target_story_flag and quest.target_story_flag.id == flag_id:
			# Update progress to max so any UI listeners show 100% completion
			active_quests[quest_id] = quest.required_amount
			quest_progress_updated.emit(quest_id, quest.required_amount, quest.required_amount)
			_complete_quest(quest)
func _on_action_triggered(action_data: ActionData) -> void:
	if not action_data: return
	
	for quest_id in active_quests.keys():
		var quest = _get_quest_data(quest_id)
		
		# Make sure the target_action resource isn't null before checking its ID
		if quest and quest.target_action and quest.target_action.id == action_data.id:
			_increment_quest_progress(quest)

# ==============================================================================
# CORE LOGIC
# ==============================================================================
func _activate_quest(quest: QuestData) -> void:
	if active_quests.has(quest.id) or completed_quests.has(quest.id): return
	
	active_quests[quest.id] = 0
	quest_activated.emit(quest)
	print("📜 New Quest Activated: ", quest.title)
	
	# NEW: Check if the objective story flag is ALREADY true upon activation
	if quest.target_story_flag and ProgressionManager.get_flag(quest.target_story_flag.id):
		# Immediately complete it
		active_quests[quest.id] = quest.required_amount
		quest_progress_updated.emit(quest.id, quest.required_amount, quest.required_amount)
		_complete_quest(quest)

func _increment_quest_progress(quest: QuestData) -> void:
	var current = active_quests[quest.id]
	current += 1
	active_quests[quest.id] = current
	
	quest_progress_updated.emit(quest.id, current, quest.required_amount)
	
	if current >= quest.required_amount:
		_complete_quest(quest)

func _complete_quest(quest: QuestData) -> void:
	# 1. Move from active to completed
	active_quests.erase(quest.id)
	completed_quests[quest.id] = true
	
	# FIX: Emit the whole quest object, not just the string ID!
	quest_completed.emit(quest) 
	
	print("✅ Quest Completed: ", quest.title)
	
	if SignalBus.has_signal("message_logged"):
		SignalBus.message_logged.emit("Quest Completed: " + quest.title, Color.GREEN)

	# ==========================================
	# 2. PAYOUT THE REWARDS
	# ==========================================
	
	# A. Currency Reward
	if quest.reward_currency and quest.reward_amount > 0:
		CurrencyManager.add_currency(quest.reward_currency.type, quest.reward_amount)
		SignalBus.message_logged.emit("Earned " + str(quest.reward_amount) + " " + quest.reward_currency.display_name, Color.GOLD)

	# B. NEW: Story Flag Reward!
	if quest.reward_story_flag:
		# ProgressionManager's set_flag will automatically handle the UI logging for us!
		ProgressionManager.set_flag(quest.reward_story_flag, true)


	# ==========================================
	# 3. CHECK FOR FOLLOW-UP QUESTS
	# ==========================================
	# Loop through all quests to see if completing THIS quest unlocks another one
	for next_quest in all_quests:
		if next_quest.prerequisite_quest and next_quest.prerequisite_quest.id == quest.id:
			# Also ensure they meet the story flag requirement for the next quest, if it has one
			if not next_quest.required_story_flag or ProgressionManager.get_flag(next_quest.required_story_flag.id):
				_activate_quest(next_quest)

# ==============================================================================
# HELPERS & SAVE DATA
# ==============================================================================
func _get_quest_data(id: String) -> QuestData:
	for q in all_quests:
		if q.id == id: return q
	return null

func get_save_data() -> Dictionary:
	return {
		"active": active_quests.duplicate(),
		"completed": completed_quests.duplicate()
	}

func load_save_data(data: Dictionary) -> void:
	active_quests = data.get("active", {})
	completed_quests = data.get("completed", {})
	_evaluate_all_quests()

func _evaluate_all_quests() -> void:
	for quest in all_quests:
		# Skip if already active or completed
		if active_quests.has(quest.id) or completed_quests.has(quest.id):
			continue
			
		var can_unlock = true
		
		# Check Story Flag
		if quest.required_story_flag and not ProgressionManager.get_flag(quest.required_story_flag.id):
			can_unlock = false
			
		# Check Prerequisite Quest
		if quest.prerequisite_quest and not completed_quests.has(quest.prerequisite_quest.id):
			can_unlock = false
			
		if can_unlock:
			_activate_quest(quest)
