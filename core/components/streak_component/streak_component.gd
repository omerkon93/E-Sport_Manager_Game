extends Node
class_name StreakComponent

# --- DEPENDENCIES ---
@export var cost_component: CostComponent
@export var reward_component: RewardComponent 

# --- CONFIGURATION ---
@export_category("Rules")
@export var enabled: bool = true
@export var safe_streak: int = 3

@export_category("Risk (Debuff)")
@export var penalty_vital: VitalDefinition.VitalType = VitalDefinition.VitalType.FOCUS
@export var penalty_per_step: float = 5.0 

@export_category("Reward (Bonus)")
@export var bonus_currency: CurrencyDefinition.CurrencyType = CurrencyDefinition.CurrencyType.MONEY
# CHANGE: Now represents a percentage (0.1 = +10% per step)
@export var bonus_multiplier_step: float = 0.1 

@export_category("Narrative")
@export var streak_messages: Dictionary[int, String] = {
	4: "Entering flow state...",
	7: "The screen is blurring...",
	10: "DANGER: High Stress!",
	15: "SYSTEM OVERLOAD"
}

# --- STATE ---
var my_action_data: ActionData
var current_streak: int = 0

func _ready() -> void:
	if not cost_component: cost_component = get_node_or_null("../CostComponent")
	if not reward_component: reward_component = get_node_or_null("../RewardComponent")
	ActionManager.action_triggered.connect(_on_any_action_triggered)

func configure(data: ActionData) -> void:
	my_action_data = data

# --- LOGIC ---

func _on_any_action_triggered(triggered_action: ActionData) -> void:
	if not enabled: return
	
	if triggered_action == my_action_data:
		_advance_streak()
	else:
		_reset_streak()

func _advance_streak() -> void:
	current_streak += 1
	
	var steps_over_safe: int = max(0, current_streak - safe_streak)
	
	# 1. Calculate Penalty (Still Flat)
	var total_penalty: float = steps_over_safe * penalty_per_step
	
	# 2. Calculate Multiplier (New!)
	# Start at 1.0 (100%). Add the steps * percentage.
	# Example: 5 steps * 0.1 = 0.5. Total = 1.5x multiplier.
	var total_multiplier: float = 1.0 + (steps_over_safe * bonus_multiplier_step)
	
	if cost_component:
		cost_component.set_penalty(penalty_vital, total_penalty)
		
	if reward_component:
		# CALL THE NEW FUNCTION
		reward_component.set_multiplier(bonus_currency, total_multiplier)
	
	if streak_messages.has(current_streak):
		SignalBus.message_logged.emit(streak_messages[current_streak], Color.ORANGE)

func _reset_streak() -> void:
	if current_streak == 0: return 
	current_streak = 0
	
	if cost_component: cost_component.set_penalty(penalty_vital, 0.0)
	
	# Reset Multiplier to 1.0 (Normal speed)
	if reward_component: reward_component.set_multiplier(bonus_currency, 1.0)
