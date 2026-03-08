extends Control
class_name ShopMenu

# ==============================================================================
# CONFIGURATION
# ==============================================================================
@export var shop_button_scene: PackedScene

@export_category("Grids")
@export var consumable_grid: GridContainer
@export var knowledge_grid: GridContainer
@export var skill_grid: GridContainer

@export_group("Settings")
## If false, items missing Story Flags will be hidden entirely.
@export var show_locked: bool = false
## If false, items already owned (Level 1+) will be removed from the list.
@export var show_purchased: bool = false 

# ==============================================================================
# LIFECYCLE
# ==============================================================================
func _ready() -> void:
	# Connect to all relevant progression changes
	ProgressionManager.upgrade_leveled_up.connect(func(_id, _l): _rebuild_ui())
	ProgressionManager.flag_changed.connect(func(_id, _v): _rebuild_ui())
	CurrencyManager.currency_changed.connect(func(_t, _a): _rebuild_ui())
	
	visibility_changed.connect(func(): if visible: _rebuild_ui())
	
	_rebuild_ui()

# ==============================================================================
# UI BUILDING
# ==============================================================================
func _rebuild_ui() -> void:
	if not shop_button_scene: return
	
	_clear_container(knowledge_grid)
	_clear_container(skill_grid)
	_clear_container(consumable_grid)
	
	for item in ItemManager.available_items:
		var target_grid: Container = null
		
		match item.item_type:
			GameItem.ItemType.KNOWLEDGE: target_grid = knowledge_grid
			GameItem.ItemType.SKILL: target_grid = skill_grid
			GameItem.ItemType.CONSUMABLE: target_grid = consumable_grid
		
		if target_grid:
			_try_add_item_button(item, target_grid)

	_update_tab_titles()

func _try_add_item_button(item: GameItem, container: Container) -> void:
	var is_unlocked = true
	var locked_reason = ""
	
	for flag in item.story_flags_requirement:
		if flag:
			var is_flag_met = ProgressionManager.get_flag(flag.id)
				
			if not is_flag_met:
				is_unlocked = false
				locked_reason = flag.display_name if flag.display_name != "" else flag.id.capitalize()
				break

	var current_lvl = ProgressionManager.get_upgrade_level(item.id)
	var is_owned = item.item_type != GameItem.ItemType.CONSUMABLE and current_lvl >= 1

	# FILTER VISIBILITY
	if not is_unlocked and not show_locked: return
	if is_owned and not show_purchased: return

	var btn = shop_button_scene.instantiate()
	container.add_child(btn)
	btn.upgrade_resource = item 
	
	if not is_unlocked:
		if btn.has_node("Button"): btn.get_node("Button").disabled = true
		btn.modulate = Color(0.4, 0.4, 0.4, 0.8) 
		btn.tooltip_text = "Locked: Requires " + locked_reason
	elif is_owned:
		btn.modulate = Color(0.5, 1.0, 0.5, 1.0)

# ==============================================================================
# TAB MANAGEMENT & HELPERS
# ==============================================================================
func _update_tab_titles() -> void:
	_apply_tab_state(knowledge_grid, knowledge_grid.get_child_count() > 0)
	_apply_tab_state(skill_grid, skill_grid.get_child_count() > 0)
	_apply_tab_state(consumable_grid, consumable_grid.get_child_count() > 0)

func _apply_tab_state(grid: Control, has_items: bool) -> void:
	if not grid: return
	var parent = grid.get_parent()
	while parent and not (parent is TabContainer):
		parent = parent.get_parent()
	if parent is TabContainer:
		var tab_page = grid
		while tab_page.get_parent() != parent:
			tab_page = tab_page.get_parent()
		var idx = parent.get_tab_idx_from_control(tab_page)
		if idx != -1:
			parent.set_tab_hidden(idx, not has_items)

func _clear_container(c: Container) -> void:
	if c:
		for child in c.get_children():
			child.queue_free()
