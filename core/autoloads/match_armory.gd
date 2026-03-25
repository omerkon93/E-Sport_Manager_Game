extends Node
class_name MatchArmory

const WEAPON_PATHS: Array[String] = ["res://game_data/weapons/"]
const SMOKE_COST: int = 300
const FLASH_COST: int = 200

var ct_armory: Dictionary = {}
var t_armory: Dictionary = {}
var all_weapons: Dictionary = {}

func _ready() -> void:
	_scan_for_weapons()
	_assign_weapons_to_roles()

func _scan_for_weapons() -> void:
	for path in WEAPON_PATHS:
		_load_dir_recursive(path)
	print("🔫 MatchArmory: Automatically loaded %d weapons." % all_weapons.size())

func _load_dir_recursive(path: String) -> void:
	var dir = DirAccess.open(path)
	if dir == null: return
		
	for file_name in dir.get_files():
		if file_name.ends_with(".tres") or file_name.ends_with(".res"):
			var resource = load(path + "/" + file_name)
			if resource is WeaponData:
				all_weapons[resource.weapon_name.to_upper()] = resource
				
	for dir_name in dir.get_directories():
		_load_dir_recursive(path + "/" + dir_name)

func _assign_weapons_to_roles() -> void:
	var fallback = WeaponData.new()
	fallback.cost = 0 # Free fallback
	
	# Grab all the guns from the loaded files
	var ak47 = all_weapons.get("AK-47", fallback)
	var m4a4 = all_weapons.get("M4A4", fallback)
	var awp = all_weapons.get("AWP", fallback)
	var mac10 = all_weapons.get("MAC-10", fallback)
	var glock = all_weapons.get("GLOCK", fallback)
	
	# --- TEAM A (CT) ARMORY ---
	ct_armory["DEFAULT"] = m4a4
	ct_armory["AWPER"] = awp
	ct_armory["ENTRY"] = mac10 # You can change this to an MP9 or MP7 later!
	ct_armory["SUPPORT"] = m4a4
	ct_armory["PISTOL"] = glock # You can change this to USP-S later!
	
	# --- TEAM B (T) ARMORY ---
	t_armory["DEFAULT"] = ak47
	t_armory["AWPER"] = awp
	t_armory["ENTRY"] = mac10
	t_armory["SUPPORT"] = ak47
	t_armory["PISTOL"] = glock

# --- Added is_team_a parameter to know which store to shop at! ---
func get_weapon_for_role(player_data: ESportPlayer, current_balance: int, is_team_a: bool) -> WeaponData:
	# Pick the right armory based on the team
	var active_armory = ct_armory if is_team_a else t_armory
	
	if not player_data: return active_armory.get("DEFAULT")
	
	var role_string: String = ESportPlayer.PlayerRole.keys()[player_data.preferred_role].to_upper()
	var desired_weapon = active_armory.get(role_string, active_armory.get("DEFAULT"))
	
	# 1. Can they afford their favorite gun?
	if current_balance >= desired_weapon.cost:
		return desired_weapon
		
	# 2. If not, can they afford a cheap SMG (Entry role weapon)?
	var cheap_weapon = active_armory.get("ENTRY")
	if current_balance >= cheap_weapon.cost:
		return cheap_weapon
		
	# 3. They are totally broke. Give them a pistol!
	return active_armory.get("PISTOL")

func buy_utility(available_money: int) -> Dictionary:
	var bought = {"smokes": 0, "flashes": 0, "cost": 0}
	var cash = available_money
	
	# 1. Always prioritize buying 1 Smoke grenade first
	if cash >= SMOKE_COST:
		bought.smokes += 1
		bought.cost += SMOKE_COST
		cash -= SMOKE_COST
		
	# 2. Spend leftover cash on Flashbangs (Max 2)
	while cash >= FLASH_COST and bought.flashes < 2:
		bought.flashes += 1
		bought.cost += FLASH_COST
		cash -= FLASH_COST
		
	return bought
