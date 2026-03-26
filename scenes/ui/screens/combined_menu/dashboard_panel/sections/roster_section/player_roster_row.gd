extends PanelContainer

@onready var stats_display: PlayerStatsDisplay = %PlayerStatsDisplay
@onready var train_button: Button = %TrainButton
@onready var swap_button: Button = %SwapButton
@onready var fire_button: Button = %FireButton # NEW!
@onready var energy_display: PlayerVitalDisplay = %EnergyDisplay
@onready var focus_display: PlayerVitalDisplay = %FocusDisplay

@export var money_resource: CurrencyDefinition.CurrencyType 
@export var training_cost: int = 100

var _is_benched: bool = false
var current_player: ESportPlayer 

func _ready() -> void:
	train_button.pressed.connect(_on_train_button_pressed)
	swap_button.pressed.connect(_on_swap_button_pressed)
	fire_button.pressed.connect(_on_fire_button_pressed) # NEW!
	
func set_player_data(player: ESportPlayer, is_benched: bool = false) -> void:
	current_player = player
	_is_benched = is_benched
	
	# ==========================================
	# 1. HANDLE EMPTY SLOTS
	# ==========================================
	if current_player == null:
		stats_display.setup_display(null)
		
		train_button.hide()
		swap_button.hide()
		fire_button.hide() # NEW! HIDE IT!
		if energy_display: energy_display.hide()
		if focus_display: focus_display.hide()
		return
		
	# ==========================================
	# 2. HANDLE REAL PLAYERS
	# ==========================================
	stats_display.setup_display(current_player)
	
	train_button.show()
	train_button.disabled = false
	swap_button.show()
	fire_button.show() # NEW! SHOW IT!
	
	if energy_display: 
		energy_display.show()
		energy_display.setup(current_player)
	if focus_display: 
		focus_display.show()
		focus_display.setup(current_player)
		
	# ==========================================
	# 3. CONFIGURE BUTTON TEXT
	# ==========================================
	if _is_benched:
		swap_button.text = "Sub In"
		swap_button.disabled = not GameManager.my_team.active_roster.has(null)
	else:
		swap_button.text = "Bench"
		swap_button.disabled = false

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
		var success = GameManager.my_team.sub_in_player(current_player)
		if success:
			SignalBus.message_logged.emit("Subbed in " + current_player.alias, Color.GREEN)
		else:
			# Optional: Play your shake animation here if they try to sub into a full team!
			SignalBus.message_logged.emit("Active Roster is Full!", Color.RED)
	else:
		GameManager.my_team.bench_player(current_player)
		SignalBus.message_logged.emit("Benched " + current_player.alias, Color.ORANGE)
		
	GameManager.roster_updated.emit()

# ==========================================
# 3. THE FIRE FUNCTION
# ==========================================
func _on_fire_button_pressed() -> void:
	if current_player == null or GameManager.my_team == null: return
	
	# 1. CANCEL THE BILL!
	if current_player.salary_subscription != null:
		# Assuming your SubscriptionItem resource has an 'id' string property.
		# If it uses the resource path instead, you would do: current_player.salary_subscription.resource_path
		var sub_id: String = current_player.salary_subscription.id 
		SubscriptionManager.unsubscribe(sub_id)
		
	# 2. FIRE THEM!
	GameManager.my_team.release_player(current_player)
	
	# 3. REDRAW THE UI!
	GameManager.roster_updated.emit()
