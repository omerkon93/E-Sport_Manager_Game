extends VBoxContainer
class_name ResearchSectionUI

@export var research_item_scene: PackedScene
@onready var research_list: VBoxContainer = %ResearchList
@onready var empty_state_label: Label = %EmptyStateLabel

func _ready() -> void:
	#ResearchManager.research_started.connect(_on_research_started)
	#ResearchManager.research_progressed.connect(_on_research_progressed)
	#ResearchManager.research_finished.connect(_on_research_finished)
	
	# Check the state immediately when the game loads
	_update_empty_state()

# --- UI LOGIC ---

func _update_empty_state() -> void:
	var is_empty = ResearchManager.research_queue.is_empty()
	
	if is_empty:
		# If there is no research, show the text and hide the scroll box
		empty_state_label.show()
		research_list.get_parent().hide() 
	else:
		# If there IS research, hide the text and show the scroll box
		empty_state_label.hide()
		research_list.get_parent().show()

# --- SIGNAL CALLBACKS ---

#func _on_research_started(item_id: String, duration: int) -> void:
	## It already looks up the item here!
	#var item = ItemManager.find_item_by_id(item_id)
	#if not item: return # Safety check
	#
	#var ui_node = research_item_scene.instantiate() as ResearchItemUI
	#research_list.add_child(ui_node)
	#
	## Pass the whole GameItem object!
	#ui_node.setup(item, 0.0, float(duration))
	#
	#_update_empty_state()

func _on_research_progressed(item_id: String, remaining: int) -> void:
	for child in research_list.get_children():
		if child is ResearchItemUI and child.tech_id == item_id:
			var total_time = child.progress_bar.max_value
			var current_time = total_time - float(remaining)
			
			child.update_progress(current_time, total_time)
			break

func _on_research_finished(item_id: String) -> void:
	for child in research_list.get_children():
		if child is ResearchItemUI and child.tech_id == item_id:
			child.queue_free() 
			
			# Wait until the end of the frame before checking the child count.
			# queue_free() takes a split second to delete the node, 
			# so if we check instantly, it will still count as being there!
			call_deferred("_update_empty_state")
			break
