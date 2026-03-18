extends Control
class_name ShopMenu

# ==============================================================================
# CONFIGURATION
# ==============================================================================
@export var shop_button_scene: PackedScene
@export var agent_button_scene: PackedScene

@export_category("Grids")
@export var consumable_grid: GridContainer
@export var knowledge_grid: GridContainer
@export var skill_grid: GridContainer
@export var agent_grid: GridContainer

@export_group("Settings")
## If false, items missing Story Flags will be hidden entirely.
@export var show_locked: bool = false
## If false, items already owned (Level 1+) will be removed from the list.
@export var show_purchased: bool = false 

# ==============================================================================
# LIFECYCLE
# ==============================================================================
func _ready() -> void:
	# Connect to all relevant progression and economy changes
	ProgressionManager.upgrade_leveled_up.connect(func(_id, _l): _rebuild_ui())
	ProgressionManager.flag_changed.connect(func(_id, _v): _rebuild_ui())
	CurrencyManager.currency_changed.connect(func(_t, _a): _rebuild_ui())
	
	visibility_changed.connect(func(): if visible: _rebuild_ui())
	
	_rebuild_ui()

# ==============================================================================
# UI BUILDING
# ==============================================================================
func _rebuild_ui() -> void:
	# Clear out the old buttons to prevent duplicates
	#_clear_container(knowledge_grid)
	#_clear_container(skill_grid)
	#_clear_container(consumable_grid)
	_clear_container(agent_grid)
	
	# 1. Build Standard Shop Items
	#if shop_button_scene:
		#for item in ItemManager.available_items:
			#var target_grid: Container = null
			#
			#match item.item_type:
				#GameItem.ItemType.KNOWLEDGE: target_grid = knowledge_grid
				#GameItem.ItemType.SKILL: target_grid = skill_grid
				#GameItem.ItemType.CONSUMABLE: target_grid = consumable_grid
			#
			#if target_grid:
				#_try_add_item_button(item, target_grid)

	# 2. Build Free Agents (Recruitment Market)
	if agent_button_scene and agent_grid:
		for agent in MarketManager.available_agents:
			_try_add_agent_button(agent, agent_grid)

	# 3. Clean up empty tabs
	_update_tab_titles()

func _try_add_agent_button(agent: ESportPlayer, container: Container) -> void:
	var btn = agent_button_scene.instantiate()
	container.add_child(btn)
	
	# Pass the data to your custom agent button so it can display the UI
	if btn.has_method("setup_agent"):
		btn.setup_agent(agent)

# ==============================================================================
# TAB MANAGEMENT & HELPERS
# ==============================================================================
func _update_tab_titles() -> void:
	_apply_tab_state(knowledge_grid, knowledge_grid and knowledge_grid.get_child_count() > 0)
	_apply_tab_state(skill_grid, skill_grid and skill_grid.get_child_count() > 0)
	_apply_tab_state(consumable_grid, consumable_grid and consumable_grid.get_child_count() > 0)
	_apply_tab_state(agent_grid, agent_grid and agent_grid.get_child_count() > 0)

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
