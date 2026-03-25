extends Resource
class_name WeaponData

@export var weapon_name: String = "AK-47"
@export var base_damage: float = 34.0 # 3 hits to kill
@export var fire_rate: float = 0.3 # Time in seconds between shots
@export var accuracy_multiplier: float = 1.0 # 1.0 is normal, 1.2 is 20% more accurate, etc.
@export var mobility: float = 1.0 # 1.0 is normal speed, 0.7 is slow (like holding an AWP)

@export_group("Economy")
@export var cost: int = 3000 # Default rifle cost
