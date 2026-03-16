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
	# Connect the button click
	train_button.pressed.connect(_on_train_button_pressed)

func set_player_data(player: ESportPlayer) -> void:
	current_player = player
	
	if current_player == null:
		name_label.text = "Empty"
		role_label.text = "-"
		aim_label.text = "-"
		sense_label.text = "-"
		teamwork_label.text = "-"
		train_button.disabled = true
		return
		
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
