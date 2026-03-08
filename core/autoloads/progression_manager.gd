extends Node

# Signals
signal upgrade_leveled_up(id: String, new_level: int)
signal flag_changed(flag_id: String, value: bool)
signal milestone_unlocked(flag_id: String, description: String)
signal item_seen(item_id: String)

# --- CONFIGURATION ---
const MILESTONE_PATH = "res://game_data/game_progression/milestones/"

# --- STATE ---
var upgrade_levels: Dictionary = {}
var story_flags: Dictionary = {}

# --- DATABASE ---
var all_milestones: Array[Milestone] = []

# --- NOTIFICATION TRACKING (NEW) ---
var seen_items: Dictionary = {}

# ==============================================================================
# LIFECYCLE
# ==============================================================================
func _ready() -> void:
	_load_milestones()
	_connect_signals()

func reset() -> void:
	upgrade_levels.clear()
	story_flags.clear()
	seen_items.clear()

func _connect_signals() -> void:
	if CurrencyManager:
		CurrencyManager.currency_changed.connect(_on_currency_changed)
	
	if VitalManager and VitalManager.has_signal("vital_changed"):
		VitalManager.vital_changed.connect(_on_vital_changed)

	if TimeManager:
		TimeManager.time_updated.connect(_on_time_updated)
		TimeManager.day_started.connect(func(_d): _check_all_milestones())

	if QuestManager and QuestManager.has_signal("quest_completed"):
		QuestManager.quest_completed.connect(_on_quest_completed)
	
	if ResearchManager and ResearchManager.has_signal("research_started"):
		ResearchManager.research_started.connect(_on_research_started)
	
	if ResearchManager and ResearchManager.has_signal("research_finished"):
		ResearchManager.research_finished.connect(_on_research_finished)
	
	if ItemManager.has_signal("consumable_purchased"):
		ItemManager.consumable_purchased.connect(_on_consumable_purchased)

func _load_milestones() -> void:
	var files = _get_all_files_recursive(MILESTONE_PATH)
	for file_path in files:
		if file_path.ends_with(".tres") or file_path.ends_with(".res"):
			var res = load(file_path)
			if res is Milestone:
				all_milestones.append(res)
				
	print("🏆 ProgressionManager: Loaded %d milestones." % all_milestones.size())
	if all_milestones.is_empty():
		push_error("ProgressionManager: No milestones found in: " + MILESTONE_PATH)

# --- HELPER: Digs through all subfolders ---
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
func _on_currency_changed(type: int, _amount: float) -> void:
	for m in all_milestones:
		if m.currency_amount > 0 and m.required_currency == type:
			_evaluate_milestone(m)

func _on_vital_changed(type: int, _current: float, _max: float) -> void:
	for m in all_milestones:
		if m.vital_amount > 0 and m.required_vital == type:
			_evaluate_milestone(m)

func _on_upgrade_leveled_internal(id: String, _level: int) -> void:
	for m in all_milestones:
		if m.required_item != null and m.required_item.id == id:
			_evaluate_milestone(m)

func _on_time_updated(_day: int, _hour: int, _minute: int) -> void:
	if _minute == 0:
		for m in all_milestones:
			if m.min_day != -1:
				_evaluate_milestone(m)

func _on_quest_completed(quest: QuestData) -> void:
	if quest.reward_story_flag != null:
		set_flag(quest.reward_story_flag, true)

func _on_research_started(id: String, _duration: int) -> void:
	for m in all_milestones:
		# Did they start the specific item, OR does this milestone just want ANY research?
		if m.any_research_started or (m.required_started_research != null and m.required_started_research.id == id):
			# Pass the exact context so the evaluator knows this is a legitimate event!
			_evaluate_milestone(m, "research_started")

func _on_research_finished(id: String) -> void:
	for m in all_milestones:
		# Did they finish the specific item, OR does this milestone just want ANY research done?
		if m.any_research_finished or (m.required_finished_research != null and m.required_finished_research.id == id):
			# Pass the exact context so the evaluator knows this is a legitimate event!
			_evaluate_milestone(m, "research_finished")

func _on_consumable_purchased(item_id: String) -> void:
	for m in all_milestones:
		if m.required_item != null and m.required_item.id == item_id:
			# Pass a specific context so the evaluator knows this is a transient event
			_evaluate_milestone(m, "consumable_purchased")

func _check_all_milestones() -> void:
	for m in all_milestones:
		_evaluate_milestone(m)

# ==============================================================================
# EVALUATION LOGIC
# ==============================================================================
func _evaluate_milestone(m: Milestone, event_context: String = "") -> void:
	if m.target_flag == null: return
	
	# Skip if already unlocked
	if get_flag(m.target_flag): return 
	
	# --- THE SAFETY CATCH (UPDATED) ---
	if m.currency_amount <= 0 and m.vital_amount <= 0 and m.min_day == -1 and m.required_item == null and m.required_started_research == null and not m.any_research_started and m.required_finished_research == null and not m.any_research_finished:
		return

	# --- EVENT CHECK (UPDATED) ---
	# If this milestone relies on a one-time event, it MUST fail passive checks unless context matches!
	if m.any_research_started or m.required_started_research != null:
		if event_context != "research_started":
			return
			
	if m.any_research_finished or m.required_finished_research != null:
		if event_context != "research_finished":
			return

	# --- A. Currency Check ---
	if m.currency_amount > 0:
		# Use get_currency_amount to match your CurrencyManager API
		var current = CurrencyManager.get_currency_amount(m.required_currency)
		if m.currency_is_less_than:
			if current >= m.currency_amount: return
		else:
			if current < m.currency_amount: return

	# --- B. Vital Check ---
	if m.vital_amount > 0 and VitalManager.has_method("get_vital_value"):
		var current = VitalManager.get_vital_value(m.required_vital)
		if m.vital_is_less_than:
			if current >= m.vital_amount: return
		else:
			if current < m.vital_amount: return

	# --- C. Time Check ---
	if m.min_day != -1:
		var current_total = (TimeManager.current_day * 24) + TimeManager.current_hour
		var target_total = (m.min_day * 24) + m.min_hour
		
		if m.time_is_deadline:
			if current_total >= target_total: return
		else:
			if current_total < target_total: return

	# --- D. Item Check ---
	if m.required_item != null:
		# 1. Did we just buy a consumable? (Our new bypass)
		var is_consumable_event = (event_context == "consumable_purchased")
		
		# 2. Do we permanently own this upgrade? (Your existing native check)
		var has_upgrade = get_upgrade_level(m.required_item.id) > 0
		
		# 3. If EITHER is true, the requirement is met!
		var has_item = has_upgrade or is_consumable_event
		
		if m.item_must_be_missing:
			if has_item: return # Fails if they HAVE the item
		else:
			if not has_item: return # Fails if they DON'T have the item

	# If it survives all checks above, it means valid requirements were met!
	unlock_milestone(m.target_flag, m.notification_text)

func unlock_milestone(flag_or_id, display_text: String) -> void:
	var id = _resolve_key(flag_or_id)
	
	if not get_flag(id):
		set_flag(id, true)
		milestone_unlocked.emit(id, display_text)
		print("🏆 Milestone Reached: ", display_text)
		if SignalBus.has_signal("message_logged"):
			SignalBus.message_logged.emit(display_text, Color.GOLD)

# ==============================================================================
# PUBLIC API
# ==============================================================================
func get_upgrade_level(id: String) -> int:
	return upgrade_levels.get(id, 0)

func increment_upgrade_level(id: String, amount: int = 1) -> void:
	var current = get_upgrade_level(id)
	var new_level = current + amount
	upgrade_levels[id] = new_level
	upgrade_leveled_up.emit(id, new_level)
	_on_upgrade_leveled_internal(id, new_level)

func get_flag(key) -> bool:
	var id = _resolve_key(key)
	return story_flags.get(id, false)

func set_flag(key, value: bool = true) -> void:
	var id = _resolve_key(key)
	if story_flags.get(id) != value:
		story_flags[id] = value
		flag_changed.emit(id, value)
		
		if value == true:
			if key is StoryFlag and key.display_name != "":
				SignalBus.message_logged.emit("Story Update: " + key.display_name, Color.MAGENTA)

		_check_all_milestones()

func _resolve_key(key) -> String:
	if key is StoryFlag: return key.id
	return str(key)

# --- NOTIFICATION API (NEW) ---
func is_item_new(id: String) -> bool:
	# It is new if it is NOT in the dictionary
	return not seen_items.has(id)

func mark_item_as_seen(id: String) -> void:
	if not seen_items.has(id):
		seen_items[id] = true
		item_seen.emit(id)
		# Note: We rely on Auto-Save to persist this to disk

# ==============================================================================
# PERSISTENCE
# ==============================================================================
func get_save_data() -> Dictionary:
	return {
		"upgrades": upgrade_levels.duplicate(),
		"flags": story_flags.duplicate(),
		"seen_items": seen_items.duplicate(),
		"quests": QuestManager.get_save_data()
	}

func load_save_data(data: Dictionary) -> void:
	upgrade_levels = data.get("upgrades", {})
	story_flags = data.get("flags", {})
	seen_items = data.get("seen_items", {})
	
	# Restore state signals
	for id in upgrade_levels: 
		upgrade_leveled_up.emit(id, upgrade_levels[id])
	
	for flag_id in story_flags: 
		flag_changed.emit(flag_id, story_flags[flag_id])
	
	_check_all_milestones()
