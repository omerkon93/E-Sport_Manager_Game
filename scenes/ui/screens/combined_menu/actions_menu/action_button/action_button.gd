extends MarginContainer
class_name ActionButton

# ==============================================================================
# 1. DATA & CONFIGURATION
# ==============================================================================

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

@export_category("Settings")
@export var base_cooldown: float = 0.5 
@export var is_study_button: bool = false 

@export_group("Upgrades")
@export var primary_upgrade: GameItem
@export var contributing_upgrades: Array[GameItem] = []

@onready var timer: Timer = $CooldownTimer
@onready var interact_button: Button = $Button 
@onready var title_label: Label = %TitleLabel
@onready var stats_label: RichTextLabel = %StatsLabel 
@onready var icon_rect: TextureRect = %IconRect
@onready var study_dialog: ConfirmationDialog = $StudyDialog

@onready var time_spinbox: SpinBox = %TimeSpinBox
@onready var dialog_stats_label: RichTextLabel = %DialogStatsLabel

var current_cooldown: float = 1.0

# ==============================================================================
# 2. LIFECYCLE
# ==============================================================================
func _ready() -> void:
	if interact_button:
		interact_button.pressed.connect(_on_pressed)
		
	if study_dialog:
		study_dialog.confirmed.connect(_on_study_dialog_confirmed)
		
	if time_spinbox:
		time_spinbox.value_changed.connect(_on_time_spinbox_changed)
		
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
	# 0. THE CRASH FIX: Make sure action_data actually exists before doing anything!
	if not action_data: 
		printerr("ActionButton pressed, but no action_data is assigned!")
		return
		
	if timer and not timer.is_stopped(): return

	# 1. CLEAR THE BADGE FIRST!
	if notification_indicator_component:
		notification_indicator_component.mark_as_seen()

	# 2. CHECK AFFORDABILITY 
	if cost_component and not cost_component.check_affordability():
		if animation_component: animation_component.play_shake()
		return

	# 3. INTERCEPT FOR DYNAMIC RANDOM TICKET
	var random_ticket = DialogueManager.get_random_ticket_for(action_data)
	if random_ticket != null:
		if cost_component: cost_component.pay_all()
		if timer: timer.start(current_cooldown)
		DialogueManager.start_dialogue(random_ticket)
		return 

	# 4. PROMPT OR EXECUTE
	if is_study_button and study_dialog and time_spinbox:
		time_spinbox.value = max(1, round(float(action_data.effective_time_cost) / 60.0))
		_on_time_spinbox_changed(time_spinbox.value)
		
		study_dialog.popup_centered()
	else:
		_execute_standard_action()

# --- Triggered when the user clicks 'OK' on the popup ---
func _on_study_dialog_confirmed() -> void:
	if time_spinbox:
		# CONVERT HOURS TO MINUTES: Multiply their input by 60 before executing!
		var requested_minutes = int(time_spinbox.value * 60)
		_execute_study_action(requested_minutes)

# --- Updates the dialog text dynamically whenever the time changes! ---
func _on_time_spinbox_changed(new_time_hours: float) -> void:
	if not dialog_stats_label: return
	
	# Since 1 hour = 1 chunk (60 mins), the chunks are just the hours requested!
	var requested_chunks: int = ceil(new_time_hours)
	
	# Pass 'true' so the text generator knows we are looking at the dialog box
	dialog_stats_label.text = _generate_stats_text(requested_chunks, true)

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

	SignalBus.action_triggered.emit(action_data)
	if timer: timer.start(current_cooldown)

# --- FOR STUDY BUTTONS ONLY (Chunking Logic) ---
func _execute_study_action(requested_minutes: int) -> void:
	# 1. Figure out how many 60-minute chunks this takes.
	var requested_chunks: int = ceil(float(requested_minutes) / 60.0)
	
	var total_time_spent: int = 0
	var chunks_executed: int = 0
	var total_feedback: Array[Dictionary] = []
	
	# 2. Loop through each chunk and try to pay for it
	for i in range(requested_chunks):
		
		# Check if the player can afford this specific chunk
		if cost_component and not cost_component.check_affordability():
			# If we are completely broke on the very first try, abort!
			if chunks_executed == 0:
				if animation_component: animation_component.play_shake()
				return
			# If we afforded some earlier chunks but can't afford this one, 
			# we just break the loop and keep what we already paid for!
			break 
			
		# Pay for the chunk
		if cost_component: 
			cost_component.pay_all()
			
		chunks_executed += 1
		
		# Calculate the time to add for this chunk
		var time_for_this_chunk = 60
		# If this is the final chunk, it might be a partial hour
		if i == requested_chunks - 1:
			var remainder = requested_minutes % 60
			if remainder > 0:
				time_for_this_chunk = remainder
				
		total_time_spent += time_for_this_chunk
		
		# Deliver rewards for this chunk
		if reward_component:
			total_feedback.append_array(reward_component.deliver_rewards())

	# 3. Apply the final accumulated totals!
	if total_time_spent > 0:
		TimeManager.advance_time(total_time_spent)
		ResearchManager.manual_study(total_time_spent)
		
		if animation_component: 
			animation_component.visualize_feedback(total_feedback)
			animation_component.play_bounce()

		SignalBus.action_triggered.emit(action_data)
		if timer: timer.start(current_cooldown)

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
	if action_data.description != "": tooltip_text = action_data.description
	
	if stats_label:
		# Pass 'false' because this is the main button, not the dialog
		stats_label.text = _generate_stats_text(1, false)

# --- UPGRADED: Now accepts a multiplier and returns the text! ---
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
		if is_dialog:
			# Show HOURS in the popup dialog
			text_lines.append("[color=gray]Time: %d hr[/color]" % int(time_spinbox.value))
		else:
			# Show base MINUTES on the normal button UI
			text_lines.append("[color=gray]Time: %d min[/color]" % int(action_data.effective_time_cost))

	return "[center]%s[/center]" % "\n".join(text_lines)

# ==============================================================================
# 7. UPGRADE LOGIC 
# ==============================================================================
func _recalculate_upgrades() -> void:
	_load_data_into_components()

func _on_upgrade_leveled(id: String, _lvl: int) -> void:
	var is_relevant: bool = false
	if primary_upgrade and primary_upgrade.id == id:
		is_relevant = true
	else:
		for upg in contributing_upgrades:
			if upg and upg.id == id:
				is_relevant = true
				break
				
	if not is_relevant and action_data:
		var upgraded_item = ItemManager.find_item_by_id(id)
		if upgraded_item != null and upgraded_item.target_action == action_data:
			is_relevant = true
	
	if is_relevant:
		_load_data_into_components()
