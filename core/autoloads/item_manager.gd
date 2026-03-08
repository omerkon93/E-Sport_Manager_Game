extends Node

# ==============================================================================
# CONFIGURATION
# ==============================================================================
const AUTO_LOAD_PATHS = [
	"res://game_data/items/knowledge/",
	"res://game_data/items/skills/",
	"res://game_data/items/consumables/" 
]

# --- SIGNALS ---
signal consumable_purchased(consumable_id: String)


var available_items: Array[GameItem] = []
var reward_calculator: RewardComponent

# ==============================================================================
# LIFECYCLE
# ==============================================================================
func _ready() -> void:
	# Note: RewardComponent is definition-aware now, so it pulls its own icons!
	reward_calculator = RewardComponent.new()
	add_child(reward_calculator)
	_scan_for_items()

# ==============================================================================
# PUBLIC API
# ==============================================================================
func try_purchase_item(item: GameItem) -> bool:
	# 1. Validation (Owned or Researching)
	if item.item_type != GameItem.ItemType.CONSUMABLE:
		if ProgressionManager.get_upgrade_level(item.id) >= 1: return false
		if item.item_type == GameItem.ItemType.SKILL and ResearchManager.is_researching(item.id):
			return false

	# 2. Check Requirements (Can we afford it?)
	for cur_def: CurrencyDefinition in item.currency_cost:
		var amt = item.currency_cost[cur_def]
		if not CurrencyManager.has_enough_currency(cur_def.type, amt):
			return false
			
	for vit_def: VitalDefinition in item.vital_cost:
		var amt = item.vital_cost[vit_def]
		if not VitalManager.has_enough(vit_def.type, amt):
			return false

	# 3. Consume Costs (Spend the resources)
	for cur_def: CurrencyDefinition in item.currency_cost:
		var amt = item.currency_cost[cur_def]
		CurrencyManager.spend_currency(cur_def.type, amt) #
		
	for vit_def: VitalDefinition in item.vital_cost:
		var amt = item.vital_cost[vit_def]
		VitalManager.consume(vit_def.type, amt) #

	# 4. Handle Acquisition
	if item.item_type == GameItem.ItemType.SKILL:
		ResearchManager.start_research(item)
		return true

	apply_level_up(item)
	return true

func find_item_by_id(id: String) -> GameItem:
	for item in available_items:
		if item.id == id: return item
	return null

## Grants rewards and status. Called by this script for Upgrades, 
## or by ResearchManager for finished Skill.
func apply_level_up(item: GameItem) -> void:
	# A. Apply Stat Boosts
	for effect in item.effects:
		if effect != null and effect.has_method("apply"): 
			effect.apply()

	# B. Unlock ALL reward flags
	for flag in item.story_flags_reward:
		if flag:
			ProgressionManager.set_flag(flag.id, true)
	
	# C. Subscriptions
	if item.subscription_to_start:
		SubscriptionManager.subscribe(item.subscription_to_start)
	
	# D. Instant Rewards (Gains)
	if item.on_purchase_action:
		_execute_action_rewards(item.on_purchase_action)

	# E. Mark Ownership OR Broadcast Consumable
	if item.item_type != GameItem.ItemType.CONSUMABLE:
		ProgressionManager.increment_upgrade_level(item.id)
		ProgressionManager.upgrade_leveled_up.emit(item.id, 1)
	else:
		consumable_purchased.emit(item.id)
	
	# F. Presentation
	SignalBus.message_logged.emit("Acquired: %s" % item.display_name, Color.CYAN)
	if item.audio_on_purchase:
		SoundManager.play_sfx(item.audio_on_purchase)
func get_upgrades_for_action(action: ActionData) -> Array[GameItem]:
	var results: Array[GameItem] = []
	for item in available_items:
		# Directly compare the resource references!
		if item.target_action == action:
			results.append(item)
			
	return results

# ==============================================================================
# PRIVATE HELPERS
# ==============================================================================
func _execute_action_rewards(action: ActionData) -> void:
	for type in action.vital_gains:
		VitalManager.restore(type, action.vital_gains[type])
	for type in action.currency_gains:
		CurrencyManager.add_currency(type, action.currency_gains[type])

func _scan_for_items() -> void:
	for path in AUTO_LOAD_PATHS:
		_load_dir_recursive(path)
		
	# --- ADD THIS VALIDATOR ---
	for item in available_items:
		for i in range(item.effects.size()):
			if item.effects[i] == null:
				push_error("🚨 DATA ERROR: Item at '%s' (ID: %s) has an empty effect slot at index %d!" % [item.resource_path, item.id, i])
	# --------------------------
	
	print("📦 ItemManager: Loaded %d items into catalog." % available_items.size())

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
					var resource = load(path + "/" + file_name)
					if resource is GameItem:
						if not available_items.any(func(x): return x.id == resource.id):
							available_items.append(resource)
			file_name = dir.get_next()
