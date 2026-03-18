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
			_update_ui()

## NEW: If this button is on a player's profile, assign them here! 
## Leave empty for global/manager actions.
@export var target_player: ESportPlayer = null

@export_category("Components")
@export_group("Local Components")
@export var cost_component: Node # Changed to Node, assuming they handle visuals now
@export var reward_component: Node
@export var message_component: Node
@export var streak_component: Node
@export var animation_component: AnimationComponent
@export var notification_indicator_component: Node

# ==============================================================================
# 2. NODE REFERENCES
# ==============================================================================
@onready var timer: Timer = $CooldownTimer
@onready var interact_button: Button = $Button 
@onready var item_info_button = %ItemInfoButton
@onready var title_label: Label = %TitleLabel
@onready var stats_label: RichTextLabel = %StatsLabel 
@onready var icon_rect: TextureRect = %IconRect

# ==============================================================================
# 3. LIFECYCLE
# ==============================================================================
func _ready() -> void:
	if interact_button:
		interact_button.pressed.connect(_on_pressed)
		
	# Listen to the global bus for stat changes so the button text updates dynamically!
	SignalBus.game_vital_changed.connect(_on_stats_changed)
	SignalBus.game_currency_changed.connect(_on_stats_changed)
	
	if animation_component and icon_rect:
		animation_component.target_control = icon_rect
		
	if action_data: 
		_update_ui()

func _on_stats_changed(_a=null, _b=null, _c=null) -> void:
	# Whenever ANY stat changes in the game, refresh the text (like disabling it if we go broke)
	_update_ui()

# ==============================================================================
# 4. INTERACTION
# ==============================================================================
func _on_pressed() -> void:
	if not action_data: return
	if action_data.use_cooldown and timer and not timer.is_stopped(): return

	if notification_indicator_component and notification_indicator_component.has_method("mark_as_seen"):
		notification_indicator_component.mark_as_seen()

	# 1. DIALOGUE CHECK (If you added this to DialogueDatabase)
	if DialogueDatabase.has_method("get_random_ticket_for"):
		var random_ticket = DialogueDatabase.get_random_ticket_for(action_data)
		if random_ticket != null:
			# Ask the Transaction Manager to pay for it first!
			if TransactionManager.try_perform_action(action_data, target_player):
				_start_cooldown()
				SignalBus.dialogue_requested.emit(random_ticket)
			else:
				if animation_component: animation_component.play_shake()
			return 

	# 2. STUDY / CHUNKING CHECK
	if action_data.is_study_action:
		SignalBus.study_dialog_requested.emit(self, action_data)
	
	# 3. STANDARD EXECUTION
	else:
		_execute_standard_action()

func _execute_standard_action() -> void:
	# Let the static TransactionManager handle ALL math, payments, and rewards!
	var success = TransactionManager.try_perform_action(action_data, target_player)
	
	if success:
		_start_cooldown()
		
		# Visual feedback (You can still use your reward component for floating text!)
		if animation_component: 
			animation_component.play_bounce()
			if reward_component and reward_component.has_method("get_feedback_array"):
				animation_component.visualize_feedback(reward_component.get_feedback_array())
	else:
		# Could not afford!
		if animation_component: animation_component.play_shake()

func _start_cooldown() -> void:
	if action_data.use_cooldown and timer:
		var cd = ActionCalculator.get_effective_cooldown(action_data, target_player)
		timer.start(cd)

# ==============================================================================
# 5. UI UPDATES & TEXT GENERATION
# ==============================================================================
func _update_ui() -> void:
	if not action_data: return
	if title_label: title_label.text = action_data.display_name
	if icon_rect: icon_rect.texture = action_data.icon
	
	if item_info_button and item_info_button.has_method("setup"):
		item_info_button.setup(action_data.display_name, action_data.description)
	
	if stats_label:
		stats_label.text = _generate_stats_text(1, false)

func _generate_stats_text(multiplier: int = 1, is_dialog: bool = false) -> String:
	var text_lines: Array[String] = []
	
	# Ask the static calculator for the actual energy cost!
	var energy_multiplier = ActionCalculator.get_energy_cost_multiplier(action_data, target_player)

	# --- COSTS ---
	for type in action_data.currency_costs:
		var amount = action_data.currency_costs[type] * multiplier
		var def = CurrencyManager.get_definition(type)
		if def and amount > 0: text_lines.append(def.format_loss(amount)) 

	for type in action_data.vital_costs:
		var amount = (action_data.vital_costs[type] * energy_multiplier) * multiplier
		var def = VitalManager.get_definition(type)
		if def and amount > 0: text_lines.append(def.format_loss(amount))

	# --- REWARDS ---
	for type in action_data.currency_gains:
		var amount = action_data.currency_gains[type] * multiplier
		var def = CurrencyManager.get_definition(type)
		if def and amount > 0: text_lines.append(def.format_gain(amount)) 

	for type in action_data.vital_gains:
		var amount = action_data.vital_gains[type] * multiplier
		var def = VitalManager.get_definition(type)
		if def and amount > 0: text_lines.append(def.format_gain(amount)) 

	# --- TIME ---
	var final_time = ActionCalculator.get_effective_time_cost(action_data, target_player)
	if final_time > 0:
		var time_icon = "🕒"
		if is_dialog:
			text_lines.append("[color=silver]%d hr %s[/color]" % [multiplier, time_icon])
		else:
			var formatted_time = TimeManager.format_duration_in_hours(roundi(final_time * multiplier))
			text_lines.append("[color=silver]%s %s[/color]" % [formatted_time, time_icon])

	return "[center]%s[/center]" % "\n".join(text_lines)
