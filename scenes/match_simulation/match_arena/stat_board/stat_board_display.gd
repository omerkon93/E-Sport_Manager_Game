extends HBoxContainer
class_name StatBoardDisplay

@onready var name_label: Label = %NameLabel
@onready var money_label: Label = %MoneyLabel
@onready var weapon_label: Label = %WeaponLabel
@onready var utility_label: Label = %UtilityLabel
@onready var kd_label: Label = %KDLabel
@onready var plus_minus_label: Label = %PlusMinusLabel
@onready var adr_label: Label = %ADRLabel
@onready var kast_label: Label = %KastLabel
@onready var rating_label: Label = %RatingLabel

# --- NEW: Added current_money to the arguments ---
func set_stats(player: ESportPlayer, stats: Dictionary, rounds_played: int, current_money: int) -> void:
	if not player: return
	
	# 1. Basic Info & Money
	name_label.text = player.alias
	
	# Set the money label (e.g., "$3400")
	money_label.text = "$%d" % current_money
	money_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2)) # Green for cash!
	
	# --- Set the Weapon Label ---
	var weapon_name = stats.get("weapon", "")
	weapon_label.text = weapon_name
	
	var util_text = stats.get("utility", "")
	
	if weapon_name == "☠️":
		weapon_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))
		utility_label.text = "" # Clear utility when dead (they dropped it!)
	else:
		weapon_label.remove_theme_color_override("font_color") 
		utility_label.text = util_text # Show the clouds and lightning bolts!
		
	# 2. Extract Stats from the MatchStats ledger
	var kills = stats.get("kills", 0)
	var deaths = stats.get("deaths", 0)
	var damage = stats.get("damage", 0.0)
	
	# 3. K/D Formatting
	kd_label.text = "%d / %d" % [kills, deaths]
	
	# 4. Plus/Minus Calculation (+/-)
	var plus_minus = kills - deaths
	if plus_minus > 0:
		plus_minus_label.text = "+%d" % plus_minus
		plus_minus_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2)) # Green
	elif plus_minus < 0:
		plus_minus_label.text = str(plus_minus)
		plus_minus_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2)) # Red
	else:
		plus_minus_label.text = "0"
		plus_minus_label.remove_theme_color_override("font_color")
		
	# 5. ADR (Average Damage per Round)
	var safe_rounds = max(1, rounds_played)
	var adr = damage / float(safe_rounds)
	adr_label.text = "%.1f" % adr
	
	# 6. Advanced Stats
	kast_label.text = "75%"
	rating_label.text = "1.05"
