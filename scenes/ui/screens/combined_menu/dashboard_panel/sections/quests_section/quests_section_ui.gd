extends VBoxContainer
class_name QuestsSectionUI

# --- COMPONENTS ---
@export var quest_item_scene: PackedScene

# --- NODES ---
@onready var quest_list: VBoxContainer = %QuestList
@onready var empty_state_label: Label = %EmptyStateLabel # <--- ADDED THIS

func _ready() -> void:
	# Removed hide() from here so the empty state text can be seen!
	
	QuestManager.quest_activated.connect(_on_quest_activated)
	QuestManager.quest_progress_updated.connect(_on_quest_progress_updated)
	QuestManager.quest_completed.connect(_on_quest_completed)
	
	_refresh_quests_ui()

# ==============================================================================
# LOGIC
# ==============================================================================
func _on_quest_activated(quest: QuestData) -> void:
	_spawn_quest_item(quest)
	_check_empty_state() # Instantly hide the empty state label

func _on_quest_progress_updated(q_id: String, _action_id: String, _current: int, _required: int) -> void:
	for child in quest_list.get_children():
		if child is QuestItemUI and child.quest_id == q_id:
			var progress_dict = QuestManager.active_quests.get(q_id, {})
			child.update_progress(progress_dict)
			break

func _on_quest_completed(quest: QuestData) -> void:
	var quest_id = quest.id
	for child in quest_list.get_children():
		if child is QuestItemUI and child.quest_id == quest_id:
			# Animate out, then delete
			var tween = create_tween()
			tween.tween_property(child, "modulate:a", 0.0, 0.3)
			tween.tween_callback(child.queue_free)
			
			# Check if we should show the empty state *after* the animation finishes
			tween.tween_callback(_check_empty_state)
			break

func _check_empty_state() -> void:
	var is_empty = QuestManager.active_quests.is_empty()
	
	if is_empty:
		# If there are no quests, show the text and hide the scroll box
		empty_state_label.show()
		quest_list.get_parent().hide()
	else:
		# If there ARE quests, hide the text and show the scroll box
		empty_state_label.hide()
		quest_list.get_parent().show()

func _refresh_quests_ui() -> void:
	for child in quest_list.get_children():
		child.queue_free()
		
	var active = QuestManager.active_quests
	
	for q_id in active.keys():
		var quest_data = QuestManager._get_quest_data(q_id)
		
		# active[q_id] is now a Dictionary!
		var current_progress_dict = active[q_id] 
		
		if quest_data:
			var item = _spawn_quest_item(quest_data)
			item.update_progress(current_progress_dict)
			
	_check_empty_state()

func _spawn_quest_item(quest: QuestData) -> QuestItemUI:
	if not quest_item_scene or not quest_list: return null
	
	var item = quest_item_scene.instantiate() as QuestItemUI
	quest_list.add_child(item)
	item.setup(quest)
	return item
