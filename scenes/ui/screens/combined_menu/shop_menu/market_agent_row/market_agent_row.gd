extends PanelContainer

# 1. Grab our new reusable component!
@onready var stats_display: PlayerStatsDisplay = %PlayerStatsDisplay

@onready var hire_button: Button = %HireButton
@onready var hire_rich_text: RichTextLabel = %HireRichText
@onready var anim_component: AnimationComponent = $AnimationComponent 

var agent_data: ESportPlayer
var _is_bought: bool = false 

func _ready() -> void:
	SignalBus.game_currency_changed.connect(_on_global_money_changed)

func _on_global_money_changed(_type: int, _amount: float) -> void:
	if agent_data == null or _is_bought: return
	var can_afford = CurrencyManager.has_enough_currency(CurrencyDefinition.CurrencyType.MONEY, agent_data.hiring_cost)
	hire_button.disabled = not can_afford

func setup_agent(agent: ESportPlayer) -> void:
	agent_data = agent
	
	# 2. Draw all the stats instantly!
	stats_display.setup_display(agent)
	
	hire_button.text = "" 
	var money_def = CurrencyManager.get_definition(CurrencyDefinition.CurrencyType.MONEY)
	if money_def:
		hire_rich_text.text = "Hire (%s)" % money_def.format_loss(agent.hiring_cost)
	else:
		hire_rich_text.text = "Hire ($%d)" % agent.hiring_cost
	
	hire_button.disabled = not CurrencyManager.has_enough_currency(CurrencyDefinition.CurrencyType.MONEY, agent.hiring_cost)
	
	if not hire_button.pressed.is_connected(_on_hire_pressed):
		hire_button.pressed.connect(_on_hire_pressed)

func _on_hire_pressed() -> void:
	if GameManager.my_team == null: return
		
	var success = TransactionManager.try_hire_agent(agent_data, GameManager.my_team, CurrencyDefinition.CurrencyType.MONEY)
	
	if success:
		hire_button.disabled = true
		hire_rich_text.text = "Hired!"
		_is_bought = true
		
		var spawn_pos = get_global_mouse_position()
		SignalBus.request_resource_text.emit(spawn_pos, CurrencyDefinition.CurrencyType.MONEY, -agent_data.hiring_cost, true)
		
		if anim_component: anim_component.play_fade_out_and_free()
		else: queue_free() 
	else:
		if anim_component: anim_component.play_shake()
