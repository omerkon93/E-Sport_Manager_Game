extends PanelContainer

# 1. Grab our new reusable component!
@onready var stats_display: PlayerStatsDisplay = %PlayerStatsDisplay

@onready var train_button: Button = %TrainButton
@onready var energy_display: PlayerVitalDisplay = %EnergyDisplay
@onready var focus_display: PlayerVitalDisplay = %FocusDisplay
@onready var swap_button: Button = %SwapButton

@export var money_resource: CurrencyDefinition.CurrencyType 
@export var training_cost: int = 100

var _is_benched: bool = false
var current_player: ESportPlayer 

func _ready() -> void:
	train_button.pressed.connect(_on_train_button_pressed)
	swap_button.pressed.connect(_on_swap_button_pressed)
	
func set_player_data(player: ESportPlayer, is_benched: bool = false) -> void:
	current_player = player
	_is_benched = is_benched
	
	# 2. Tell the component to draw the basic text!
	stats_display.setup_display(current_player)
	
	if current_player == null:
		train_button.disabled = true
		swap_button.hide()
		return
		
	swap_button.show()
	
	if _is_benched:
		swap_button.text = "Sub In"
		swap_button.disabled = not GameManager.my_team.active_roster.has(null)
	else:
		swap_button.text = "Bench"
		swap_button.disabled = false
	
	if energy_display: energy_display.setup(current_player)
	if focus_display: focus_display.setup(current_player)
	
	train_button.disabled = false

func _on_train_button_pressed() -> void:
	if current_player == null or money_resource == null: return
		
	if CurrencyManager.has_enough_currency(money_resource, training_cost): 
		CurrencyManager.spend_currency(money_resource, training_cost)
		current_player.aim += 1
		set_player_data(current_player) 
	else:
		print("Not enough money to train!")

func _on_swap_button_pressed() -> void:
	if current_player == null or GameManager.my_team == null: return
	
	if _is_benched:
		GameManager.my_team.sub_in_player(current_player)
	else:
		GameManager.my_team.bench_player(current_player)
		
	GameManager.roster_updated.emit()
