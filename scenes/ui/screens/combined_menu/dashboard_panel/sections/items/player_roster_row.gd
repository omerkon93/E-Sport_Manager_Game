extends PanelContainer

@onready var name_label: Label = %NameLabel
@onready var role_label: Label = %RoleLabel
@onready var aim_label: Label = %AimLabel
@onready var sense_label: Label = %SenseLabel
@onready var teamwork_label: Label = %TeamworkLabel
@onready var train_button: Button = %TrainButton

# Drag game_data/game_resources/currencies/money.tres into this in the inspector!
@export var money_resource: CurrencyDefinition.CurrencyType 
@export var training_cost: int = 100

# 1. Grab references to your new vital displays (Make sure Unique Names match!)
@onready var energy_display: PlayerVitalDisplay = %EnergyDisplay
@onready var focus_display: PlayerVitalDisplay = %FocusDisplay
@onready var swap_button: Button = %SwapButton

# Remember where this player is sitting
var _is_benched: bool = false

# We need to remember WHICH player this row belongs to
var current_player: ESportPlayer 

const ROLE_NAMES = {
	ESportPlayer.PlayerRole.ENTRY_FRAGGER: "ENTRY",
	ESportPlayer.PlayerRole.AWPER: "AWPER",
	ESportPlayer.PlayerRole.IGL: "IGL",
	ESportPlayer.PlayerRole.SUPPORT: "SUPPORT",
	ESportPlayer.PlayerRole.LURKER: "LURKER"
}

func _ready() -> void:
	train_button.pressed.connect(_on_train_button_pressed)
	swap_button.pressed.connect(_on_swap_button_pressed)
	
func set_player_data(player: ESportPlayer, is_benched: bool = false) -> void:
	current_player = player
	_is_benched = is_benched
	
	if current_player == null:
		name_label.text = "Empty Slot"
		role_label.text = "-"
		aim_label.text = "-"
		sense_label.text = "-"
		teamwork_label.text = "-"
		train_button.disabled = true
		swap_button.hide()
		return
		
	swap_button.show()
	
	# Change the button text depending on where they are!
	if _is_benched:
		swap_button.text = "Sub In"
		# Disable Sub In if active roster is full (doesn't have any nulls)
		swap_button.disabled = not GameManager.my_team.active_roster.has(null)
	else:
		swap_button.text = "Bench"
		swap_button.disabled = false
	
	# 2. THE CRITICAL STEP: Tell the widgets which player to listen to!
	if energy_display:
		energy_display.setup(current_player)
	if focus_display:
		focus_display.setup(current_player)
	
	train_button.disabled = false
	name_label.text = current_player.alias
	role_label.text = ROLE_NAMES.get(current_player.preferred_role, "UNKNOWN")
	aim_label.text = str(current_player.aim)
	sense_label.text = str(current_player.game_sense)
	teamwork_label.text = str(current_player.teamwork)

func _on_train_button_pressed() -> void:
	if current_player == null or money_resource == null:
		return
		
	# 1. Check if the player has enough money. 
	# Note: Replace "has_enough" and "remove_currency" with the exact 
	# function names you use in your CurrencyManager script!
	if CurrencyManager.has_enough_currency(money_resource, training_cost): 
		# 2. Spend the money
		CurrencyManager.spend_currency(money_resource, training_cost)
		
		# 3. Increase the stat
		current_player.aim += 1
		
		# 4. Refresh the UI so you can watch the number go up!
		set_player_data(current_player) 
	else:
		print("Not enough money to train!")

func _on_swap_button_pressed() -> void:
	if current_player == null or GameManager.my_team == null: return
	
	if _is_benched:
		GameManager.my_team.sub_in_player(current_player)
	else:
		GameManager.my_team.bench_player(current_player)
		
	# Tell the Dashboard to redraw the tables!
	GameManager.roster_updated.emit()
