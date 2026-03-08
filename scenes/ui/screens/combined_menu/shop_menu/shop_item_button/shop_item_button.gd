extends MarginContainer
class_name ShopItemButton

# ==============================================================================
# 1. DATA & CONFIG
# ==============================================================================
@export var upgrade_resource: GameItem :
	set(value):
		upgrade_resource = value
		if is_node_ready(): 
			_update_label()
			_update_display()

var color_affordable: Color = Color.WHITE
var color_expensive: Color = Color(1, 0.4, 0.4, 1.0)
var color_owned: Color = Color(0.5, 1.0, 0.5, 1.0) 

#Safely get the Notification Component if it exists in the scene
@export var notification_indicator: NotificationIndicatorComponent

# --- NODES ---
@onready var interact_button: Button = $Button 
@onready var icon_rect: TextureRect = %IconRect
@onready var title_label: Label = %TitleLabel
@onready var stats_label: RichTextLabel = %StatsLabel




# ==============================================================================
# 2. LIFECYCLE
# ==============================================================================
func _ready() -> void:
	if interact_button:
		interact_button.pressed.connect(_on_pressed)
	
	# Global State Sync
	ProgressionManager.upgrade_leveled_up.connect(_on_level_changed)
	CurrencyManager.currency_changed.connect(_on_currency_changed)
	
	# Research Manager Sync
	ResearchManager.research_started.connect(func(_id, _dur): _update_label())
	ResearchManager.research_finished.connect(func(_id): _update_label())
	
	_update_label()
	_update_display()

# ==============================================================================
# 3. INTERACTION & LOGIC
# ==============================================================================
func _on_pressed() -> void:
	if not upgrade_resource: return
	
	# 1. CLEAR THE BADGE FIRST!
	if notification_indicator:
		notification_indicator.mark_as_seen()
	
	# 2. Try to purchase. 
	if ItemManager.try_purchase_item(upgrade_resource):
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.05)
		tween.tween_property(self, "scale", Vector2.ONE, 0.1)
		_update_label()

func _update_label() -> void:
	if not upgrade_resource or not is_node_ready(): return
	var res = upgrade_resource
	
	var level = ProgressionManager.get_upgrade_level(res.id)
	var is_skill = res.item_type == GameItem.ItemType.SKILL
	var researching = is_skill and ResearchManager.is_researching(res.id)

	# --- A. STATE: OWNED OR RESEARCHING ---
	if res.item_type != GameItem.ItemType.CONSUMABLE:
		if level >= 1:
			title_label.text = res.display_name
			stats_label.text = "[center](Owned)[/center]"
			interact_button.disabled = true
			modulate = color_owned
			_configure_notification(res.id) # Check notification
			return
		
		if researching:
			title_label.text = res.display_name
			stats_label.text = "[center][color=cyan](Researching...)[/color][/center]"
			interact_button.disabled = true
			modulate = Color(0.7, 0.7, 1.0, 0.8)
			_configure_notification(res.id) # Check notification
			return

	# --- B. STATE: AVAILABLE FOR PURCHASE ---
	interact_button.disabled = false
	title_label.text = res.display_name
	
	var cost_strings: Array[String] = []
	var can_afford = true
	
	# 1. Process Currencies Dictionary [Resource -> int]
	for cur_def: CurrencyDefinition in res.currency_cost:
		var amount = res.currency_cost[cur_def]
		if CurrencyManager.get_currency_amount(cur_def.type) < amount: 
			can_afford = false
		cost_strings.append(cur_def.format_loss(amount))

	# 2. Process Vitals Dictionary [Resource -> int]
	for vit_def: VitalDefinition in res.vital_cost:
		var amount = res.vital_cost[vit_def]
		if VitalManager.get_current(vit_def.type) < amount: 
			can_afford = false
		cost_strings.append(vit_def.format_loss(amount))
	
	var cost_text = "Cost: Free" if cost_strings.is_empty() else " + ".join(cost_strings)
	
	# Combine effects logic and costs
	stats_label.text = "[center]%s\n%s[/center]" % [_get_effects_text(), cost_text]
	modulate = color_affordable if can_afford else color_expensive

	# NEW: Trigger the notification pulse check at the end of updating
	_configure_notification(res.id)


# ==============================================================================
# 4. HELPERS
# ==============================================================================
func _configure_notification(item_id: String) -> void:
	if notification_indicator:
		notification_indicator.configure(item_id, self)
	
func _on_level_changed(_id, _lvl): _update_label()
func _on_currency_changed(_t, _a): _update_label()
func _update_display(): if upgrade_resource and icon_rect: icon_rect.texture = upgrade_resource.icon

func _get_effects_text() -> String:
	var parts = []
	var res = upgrade_resource
	
	# 1. Tech Research Time
	if res.item_type == GameItem.ItemType.SKILL:
		var base_time = res.research_duration_minutes
		var speed = ResearchManager.get_global_research_speed()
		var effective_time = int(base_time / speed)
		var time_str = "%dm" % effective_time
		if effective_time >= 60:
			var hours = int(effective_time / 60.0)
			var mins = effective_time % 60
			time_str = "%dh %dm" % [hours, mins]
		parts.append("[color=cyan]Research Time: %s[/color]" % time_str)
		
	# 2. Permanent Stat Effects
	for effect in res.effects:
		if effect != null and "stat" in effect and "amount" in effect:
			var amount = effect.amount
			var stat_key = StatDefinition.StatType.find_key(effect.stat)
			var stat_name = stat_key.capitalize() if stat_key else "Stat"
			var sign_str = "+" if amount >= 0 else ""
			
			if "is_percentage" in effect and effect.is_percentage:
				parts.append("[color=light_green]%s%d%% %s[/color]" % [sign_str, int(amount * 100), stat_name])
			else:
				var val_str = str(int(amount)) if is_equal_approx(amount, round(amount)) else "%.1f" % amount
				parts.append("[color=light_green]%s%s %s[/color]" % [sign_str, val_str, stat_name])
	# 3. Feature Unlocks (Now looping through the ARRAY)
	for flag in res.story_flags_reward:
		if flag:
			var label = flag.display_name if flag.display_name != "" else flag.id.capitalize().replace("_", " ")
			parts.append("[color=violet]Unlocks: %s[/color]" % label)

	# 4. Immediate Action Rewards (Gains)
	if res.on_purchase_action:
		var action = res.on_purchase_action
		if action.effective_time_cost > 0:
			parts.append("[color=gray]🕒 Takes: %d min[/color]" % int(action.effective_time_cost))
		
		for type in action.vital_gains:
			var amount = action.vital_gains[type]
			if amount > 0:
				var def = VitalManager.get_definition(type)
				if def: parts.append(def.format_gain(amount))
				
		for type in action.currency_gains:
			var amount = action.currency_gains[type]
			if amount > 0:
				var def = CurrencyManager.get_definition(type)
				if def: parts.append(def.format_gain(amount))

	# 5. Subscriptions
	if res.subscription_to_start:
		var sub = res.subscription_to_start
		parts.append("[color=orange]Starts: %s ($%d / %d days)[/color]" % [sub.display_name, sub.cost_amount, sub.interval_days])

	return "\n".join(parts)
