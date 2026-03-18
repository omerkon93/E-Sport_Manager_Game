extends Control
class_name ActionsMenu

# --- CONFIGURATION ---
@export var action_button_scene: PackedScene

@export_category("Grids")
@export var career_grid: GridContainer
@export var survival_grid: GridContainer

const NEW_INDICATOR: String = " (!)"

func _ready() -> void:
	# Rebuilds the whole list (e.g. unlocks new buttons)
	ProgressionManager.flag_changed.connect(func(_id, _val): _rebuild_ui())
	
	# Rebuild when a quest finishes!
	if QuestManager.has_signal("quest_completed"):
		QuestManager.quest_completed.connect(func(_quest): _rebuild_ui())
	
	# Only updates the tab titles (e.g. removes "(!)") - No scroll reset!
	ProgressionManager.item_seen.connect(func(_id): _update_tab_titles())
	
	if visible:
		_rebuild_ui()

func _on_visibility_changed() -> void:
	if visible:
		_rebuild_ui()

# --- 1. HEAVY LIFTING: Create Buttons ---
func _rebuild_ui() -> void:
	if not action_button_scene: return
	
	_clear_all_grids()
	
	for action in ActionManager.all_actions:
		if not action.is_visible_in_menu: continue
		
		# --- NEW: Use the centralized Manager check! ---
		if not ActionManager.is_action_unlocked(action):
			continue
		
		# Instantiate
		match action.category:
			ActionData.ActionCategory.CAREER:
				_create_action_button(action, career_grid)
			ActionData.ActionCategory.SURVIVAL:
				_create_action_button(action, survival_grid)
			_:
				_create_action_button(action, career_grid)
	
	# Update tabs immediately after building
	_update_tab_titles()

# --- 2. LIGHTWEIGHT: Update Tabs & Notifications ---
func _update_tab_titles() -> void:
	# Scan data to see what is visible/new
	var status_career = _get_category_status(ActionData.ActionCategory.CAREER)
	var status_survival = _get_category_status(ActionData.ActionCategory.SURVIVAL)
	
	_apply_tab_state(career_grid, status_career.has_items, status_career.has_new)
	_apply_tab_state(survival_grid, status_survival.has_items, status_survival.has_new)

	# --- NEW: Bubble the notification up to the Main Menu Tab! ---
	var any_new_actions = status_career.has_new or status_survival.has_new
	_apply_tab_state(self, true, any_new_actions)

# --- HELPERS ---
func _get_category_status(cat: int) -> Dictionary:
	var has_items = false
	var has_new = false
	
	for action in ActionManager.all_actions:
		if action.category != cat: continue
		if not action.is_visible_in_menu: continue
		
		if not ActionManager.is_action_unlocked(action): 
			continue
		
		has_items = true
		if ProgressionManager.is_item_new(action.id):
			has_new = true
	
	return { "has_items": has_items, "has_new": has_new }

func _apply_tab_state(grid: Control, show_tab: bool, show_indicator: bool) -> void:
	if not grid: return
	
	# Start climbing from the grid
	var current_node = grid
	var parent_node = current_node.get_parent()
	
	while parent_node:
		if parent_node is TabContainer:
			var container = parent_node as TabContainer
			
			# FIX: 'current_node' is the node we just stepped up from.
			# It is guaranteed to be the direct child of the TabContainer.
			var idx = container.get_tab_idx_from_control(current_node)
			
			if idx != -1:
				# 1. Hide/Show
				container.set_tab_hidden(idx, not show_tab)
				
				# 2. Title Logic
				var title = container.get_tab_title(idx).replace(NEW_INDICATOR, "")
				if show_indicator: title += NEW_INDICATOR
				container.set_tab_title(idx, title)
			
			return # Found and handled
		
		# Climb up one level
		current_node = parent_node
		parent_node = current_node.get_parent()
		
		# Stop if we hit the script root or run out of parents
		if parent_node == self or parent_node == null: 
			return

func _create_action_button(data: ActionData, container: GridContainer) -> void:
	if not container: return
	var btn = action_button_scene.instantiate()
	container.add_child(btn)
	if "action_data" in btn: btn.action_data = data
	elif btn.has_method("setup"): btn.setup(data)

func _clear_all_grids() -> void:
	for g in [career_grid, survival_grid]:
		if g: for c in g.get_children(): c.queue_free()
