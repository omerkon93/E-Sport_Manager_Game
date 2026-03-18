class_name ESportPlayer
extends Resource

## 👤 Identity & Meta
@export_group("Identity & Meta")
@export var real_name: String = "John Doe"
@export var alias: String = "NoobSlayer99"
@export var age: int = 21
@export var nationality: String = "International"

enum PlayerRole { ENTRY_FRAGGER, AWPER, IGL, SUPPORT, LURKER }
@export var preferred_role: PlayerRole = PlayerRole.ENTRY_FRAGGER

## ⚔️ Core CS:GO Stats (1-100 scale)
@export_group("Core CS:GO Stats")
@export_range(1, 100) var aim: int = 50
@export_range(1, 100) var reflexes: int = 50
@export_range(1, 100) var game_sense: int = 50
@export_range(1, 100) var teamwork: int = 50

## 💰 Managerial Data
@export_group("Managerial Data")
@export var market_value: int = 50000
@export var hiring_cost: int = 50000
@export var popularity: int = 15
@export var contract_length_weeks: int = 52
@export var salary_subscription: Resource

## ❤️ Vitals (Dynamic Stats)
@export_group("Vitals")
signal vital_changed(vital_type: int, current: float, max_val: float)

@export var max_morale: float = 100.0
@export var current_morale: float = 100.0

@export var max_energy: float = 100.0
@export var current_energy: float = 100.0

@export var max_focus: float = 100.0 
@export var current_focus: float = 100.0

# --- THE SINGLE SOURCE OF TRUTH ---
func change_vital(type: VitalDefinition.VitalType, amount: float) -> void:
	var current_val = 0.0
	var max_val = 0.0
	
	if type == VitalDefinition.VitalType.ENERGY:
		current_energy = clampf(current_energy + amount, 0.0, max_energy)
		current_val = current_energy
		max_val = max_energy
		
	elif type == VitalDefinition.VitalType.FOCUS:
		current_focus = clampf(current_focus + amount, 0.0, max_focus)
		current_val = current_focus
		max_val = max_focus

	# 1. Local emission (for a specific player's UI card)
	vital_changed.emit(type, current_val, max_val)
	
	# 2. Global emission (so the global Progression/Quest systems can hear it!)
	if SignalBus.has_signal("game_vital_changed"):
		SignalBus.game_vital_changed.emit(type, current_val, max_val)

## Helper function used by TransactionManager
func has_enough_vital(type: VitalDefinition.VitalType, amount: float) -> bool:
	if type == VitalDefinition.VitalType.ENERGY: return current_energy >= amount
	if type == VitalDefinition.VitalType.FOCUS: return current_focus >= amount
	return false
