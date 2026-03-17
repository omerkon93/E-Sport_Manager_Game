extends PanelContainer

@onready var name_label: Label = %NameLabel
@onready var hire_button: Button = %HireButton

var agent_data: ESportPlayer

func setup_agent(agent: ESportPlayer) -> void:
	agent_data = agent
	name_label.text = agent.alias
	hire_button.text = "Hire ($%d)" % agent.hiring_cost
	
	# Optional: Disable the button if you can't afford them!
	hire_button.disabled = not CurrencyManager.has_enough_currency(CurrencyDefinition.CurrencyType.MONEY, agent.hiring_cost)
	
	# Connect the button
	if not hire_button.pressed.is_connected(_on_hire_pressed):
		hire_button.pressed.connect(_on_hire_pressed)

func _on_hire_pressed() -> void:
	# 1. Check if the global team loaded properly
	if GameManager.my_team == null:
		push_error("Cannot hire: No active team found in GameManager!")
		return
		
	# 2. Try to buy the player! (We use type 0 or whatever your MONEY enum is)
	# I'm assuming MONEY is 0 or you have it in an Enum. Replace '0' with your actual Money ID if different!
	var money_id = CurrencyDefinition.CurrencyType.MONEY if "CurrencyType" in CurrencyDefinition else 0
	
	if MarketManager.try_hire_agent(agent_data, GameManager.my_team, money_id):
		# 3. Disable the button so they can't double-click it
		hire_button.disabled = true
		hire_button.text = "Hired!"
		
		# 4. Trick the shop into refreshing so the hired player disappears from the list
		CurrencyManager.currency_changed.emit(money_id, 0)
