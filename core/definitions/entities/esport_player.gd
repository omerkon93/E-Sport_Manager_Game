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

## ❤️ Vitals (Dynamic Stats)
# Note: In-game, these will be handled by your vitals_monitor, 
# but we store the baseline/max values here.
@export_group("Vitals")
@export var max_energy: float = 100.0
@export var max_morale: float = 100.0

## 💰 Managerial Data
@export_group("Managerial Data")
@export var market_value: int = 50000
@export var popularity: int = 15
@export var contract_length_weeks: int = 52

# This hooks directly into your existing subscription system!
# When you hire the player, you add this subscription to the SubscriptionManager.
# When you fire them, you remove it.
@export var salary_subscription: Resource
