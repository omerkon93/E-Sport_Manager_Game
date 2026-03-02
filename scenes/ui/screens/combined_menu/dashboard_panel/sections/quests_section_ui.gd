extends VBoxContainer
class_name QuestsSectionUI

# --- COMPONENTS ---
@export var quest_item_scene: PackedScene

# --- NODES ---
@onready var quest_list: VBoxContainer = $QuestList

func _ready() -> void:
	hide() # Hidden by default if no active quests
	
	QuestManager.quest_activated.connect(_on_quest_activated)
	QuestManager.quest_progress_updated.connect(_on_quest_progress_updated)
	QuestManager.quest_completed.connect(_on_quest_completed)
	
	_refresh_quests_ui()

# ==============================================================================
# LOGIC
# ==============================================================================
func _on_quest_activated(quest: QuestData) -> void:
	_spawn_quest_item(quest)
	show()

func _on_quest_progress_updated(q_id: String, current: int, required: int) -> void:
	for child in quest_list.get_children():
		if child is QuestItemUI and child.quest_id == q_id:
			child.update_progress(current, required)
			break

func _on_quest_completed(quest: QuestData) -> void:
	var quest_id = quest.id
	for child in quest_list.get_children():
		if child is QuestItemUI and child.quest_id == quest_id:
			# Animate out, then delete
			var tween = create_tween()
			tween.tween_property(child, "modulate:a", 0.0, 0.3)
			tween.tween_callback(child.queue_free)
			
			# NEW: Check if we should hide the UI *after* the animation finishes
			tween.tween_callback(_check_empty_state)
			break

func _check_empty_state() -> void:
	# Only hide the container if the backend confirms there are no active quests
	if QuestManager.active_quests.is_empty():
		hide()

func _refresh_quests_ui() -> void:
	for child in quest_list.get_children():
		child.queue_free()
		
	var active = QuestManager.active_quests
	if active.is_empty():
		hide()
		return
		
	show()
	
	for q_id in active.keys():
		var quest_data = QuestManager._get_quest_data(q_id)
		var current_progress = active[q_id]
		
		if quest_data:
			var item = _spawn_quest_item(quest_data)
			item.update_progress(current_progress, quest_data.required_amount)

func _spawn_quest_item(quest: QuestData) -> QuestItemUI:
	if not quest_item_scene or not quest_list: return null
	
	var item = quest_item_scene.instantiate() as QuestItemUI
	quest_list.add_child(item)
	item.setup(quest)
	return item
