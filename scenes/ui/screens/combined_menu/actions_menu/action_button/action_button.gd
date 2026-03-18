extends MarginContainer
class_name ActionButton

# ==============================================================================
# 1. DATA & CONFIGURATION
# ==============================================================================

@export_category("Data")
@export var action_data: ActionData:
	set(value):
		action_data = value
		if is_node_ready(): 
			_load_data_into_components()

@export_category("Components")
@export_group("Local Components")
@export var cost_component: CostComponent
@export var reward_component: RewardComponent
@export var message_component: MessageComponent
@export var streak_component: StreakComponent
@export var animation_component: AnimationComponent
@export var notification_indicator_component: NotificationIndicatorComponent

# ==============================================================================
# 2. NODE REFERENCES
# ==============================================================================
# --- Logic Nodes ---
@onready var timer: Timer = $CooldownTimer

# --- Interactive UI ---
@onready var interact_button: Button = $Button 
@onready var item_info_button: ItemInfoButton = %ItemInfoButton

# --- Visual UI ---
@onready var title_label: Label = %TitleLabel
@onready var stats_label: RichTextLabel = %StatsLabel 
@onready var icon_rect: TextureRect = %IconRect



# ==============================================================================
# 2. LIFECYCLE
# ==============================================================================
func _ready() -> void:
	if interact_button:
		interact_button.pressed.connect(_on_pressed)
		
	# DELETED the old spinbox and dialog signal connections here
		
	ProgressionManager.upgrade_leveled_up.connect(_on_upgrade_leveled)
	_validate_and_connect_components()
	
	if action_data: 
		_load_data_into_components()
		_recalculate_upgrades() 
	
	if animation_component and icon_rect:
		animation_component.target_control = icon_rect

# ==============================================================================
# 3. INTERACTION
# ==============================================================================
func _on_pressed() -> void:
	if not action_data: 
		printerr("ActionButton pressed, but no action_data is assigned!")
		return
		
	if action_data.use_cooldown and timer and not timer.is_stopped(): 
		return

	if notification_indicator_component:
		notification_indicator_component.mark_as_seen()

	if cost_component and not cost_component.check_affordability():
		if animation_component: animation_component.play_shake()
		return

	var random_ticket = DialogueManager.get_random_ticket_for(action_data)
	if random_ticket != null:
		if cost_component: cost_component.pay_all()
		if action_data.use_cooldown and timer: 
			timer.start(action_data.effective_cooldown)
		DialogueManager.start_dialogue(random_ticket)
		return 

	# 4. PROMPT OR EXECUTE
	if action_data.is_study_action:
		# Tell the global popup to open and pass 'self' (this specific button) to it!
		SignalBus.study_dialog_requested.emit(self)
	else:
		_execute_standard_action()

# --- FOR NORMAL BUTTONS ---
func _execute_standard_action() -> void:
	if cost_component: cost_component.pay_all()
	
	TimeManager.advance_time(int(action_data.effective_time_cost))
	
	var feedback: Array[Dictionary] = []
	if reward_component:
		feedback.append_array(reward_component.deliver_rewards())
	
	if animation_component: 
		animation_component.visualize_feedback(feedback)
		animation_component.play_bounce()

	ActionManager.action_triggered.emit(action_data)
	if action_data.use_cooldown and timer: 
			timer.start(action_data.effective_cooldown)

# --- FOR STUDY BUTTONS ONLY (Chunking Logic) ---
# NOTE: The global popup will call this function directly and pass in the requested_minutes!
func _execute_study_action(requested_minutes: int) -> void:
	var requested_chunks: int = ceili(float(requested_minutes) / 60.0)
	var total_time_spent: int = 0
	var chunks_executed: int = 0
	var total_feedback: Array[Dictionary] = []
	
	for i in range(requested_chunks):
		if cost_component and not cost_component.check_affordability():
			if chunks_executed == 0:
				if animation_component: animation_component.play_shake()
				return
				
			if SignalBus: 
				SignalBus.message_logged.emit("Study cut short: Insufficient resources.", Color.ORANGE)
			break
			
		if cost_component: 
			cost_component.pay_all()
			
		chunks_executed += 1
		
		var time_for_this_chunk = 60
		if i == requested_chunks - 1:
			var remainder = requested_minutes % 60
			if remainder > 0:
				time_for_this_chunk = remainder
				
		total_time_spent += time_for_this_chunk
		
		if reward_component:
			total_feedback.append_array(reward_component.deliver_rewards())

	if total_time_spent > 0:
		TimeManager.advance_time(total_time_spent)
		ResearchManager.manual_study(total_time_spent)
		
		if animation_component: 
			animation_component.visualize_feedback(total_feedback)
			animation_component.play_bounce()

		ActionManager.action_triggered.emit(action_data)
		if action_data.use_cooldown and timer: 
			timer.start(action_data.effective_cooldown)

# ==============================================================================
# 4. SETUP HELPERS & UI UPDATES 
# ==============================================================================
func _validate_and_connect_components() -> void:
	if not cost_component: cost_component = get_node_or_null("CostComponent")
	if not reward_component: reward_component = get_node_or_null("RewardComponent")
	if not message_component: message_component = get_node_or_null("MessageComponent")
	if not streak_component: streak_component = get_node_or_null("StreakComponent")
	if not animation_component: animation_component = get_node_or_null("AnimationComponent")

func _load_data_into_components() -> void:
	if not action_data: return
	action_data.recalculate_stats()
	if reward_component:
		reward_component.configure(action_data)
		reward_component.recalculate_finals(action_data.extra_power_bonus)
	if cost_component:
		cost_component.configure(action_data)
	if notification_indicator_component:
		notification_indicator_component.configure(action_data.id, self)
	_update_ui()

func _update_ui() -> void:
	if not action_data: return
	if title_label: title_label.text = action_data.display_name
	if icon_rect: icon_rect.texture = action_data.icon
	
	if item_info_button:
		item_info_button.setup(action_data.display_name, action_data.description)
	
	if stats_label:
		stats_label.text = _generate_stats_text(1, false)

func _generate_stats_text(multiplier: int = 1, is_dialog: bool = false) -> String:
	if not action_data: return ""
	var text_lines: Array[String] = []
	
	var currency_costs = cost_component.final_currency_costs if cost_component else action_data.currency_costs
	var vital_costs = cost_component.final_vital_costs if cost_component else action_data.vital_costs

	for type in currency_costs:
		var amount = currency_costs[type] * multiplier
		var def = CurrencyManager.get_definition(type)
		if def and amount > 0: text_lines.append(def.format_loss(amount)) 

	for type in vital_costs:
		var amount = vital_costs[type] * multiplier
		var def = VitalManager.get_definition(type)
		if def and amount > 0: text_lines.append(def.format_loss(amount))

	var currency_gains = reward_component.final_currency_gains if reward_component else action_data.currency_gains
	var vital_gains = reward_component.final_vital_gains if reward_component else action_data.vital_gains

	for type in currency_gains:
		var amount = currency_gains[type] * multiplier
		var def = CurrencyManager.get_definition(type)
		if def and amount > 0: text_lines.append(def.format_gain(amount)) 

	for type in vital_gains:
		var amount = vital_gains[type] * multiplier
		var def = VitalManager.get_definition(type)
		if def and amount > 0: text_lines.append(def.format_gain(amount)) 

	if action_data.effective_time_cost > 0:
		var time_icon = "🕒"
		if is_dialog:
			# For the popup/dialog
			text_lines.append("[color=silver]%d hr %s[/color]" % [multiplier, time_icon])
		else:
			# For the main button list
			var formatted_time = TimeManager.format_duration_in_hours(roundi(action_data.effective_time_cost * multiplier))
			text_lines.append("[color=silver]%s %s[/color]" % [formatted_time, time_icon])

	return "[center]%s[/center]" % "\n".join(text_lines)

# ==============================================================================
# 7. UPGRADE LOGIC 
# ==============================================================================
func _recalculate_upgrades() -> void:
	_load_data_into_components()

func _on_upgrade_leveled(id: String, _lvl: int) -> void:
	if not action_data: 
		return
		
	#var upgraded_item = ItemManager.find_item_by_id(id)
	
	#if upgraded_item != null and upgraded_item.target_action == action_data:
		#_load_data_into_components()
