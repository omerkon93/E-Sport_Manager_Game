extends ColorRect

@onready var title_label: Label = %TitleLabel
@onready var score_label: Label = %ScoreLabel
@onready var reward_label: Label = %RewardLabel
@onready var close_button: Button = %CloseButton

# We will need your money resource to actually award the prize!
@export var money_resource: CurrencyDefinition.CurrencyType

## This is the function we call right after the match finishes!
func display_results(results: Dictionary) -> void:
	# 1. Update the Title
	if results.get("player_won", false):
		title_label.text = "VICTORY!"
		title_label.modulate = Color(0.2, 0.8, 0.2) # Green text
	else:
		title_label.text = "DEFEAT!"
		title_label.modulate = Color(0.8, 0.2, 0.2) # Red text
		
	# 2. Update the Score (Using the new keys from the Simulator!)
	score_label.text = "Your Team: %d  |  Enemy Team: %d" % [results["score_a"], results["score_b"]]
	
	# 3. Update the Reward (With a safe fallback for MVP testing)
	# 3. Update the Reward
	var default_prize = 1000 if results.get("player_won", false) else 250
	var prize: int = results.get("prize_money", default_prize)
	
	reward_label.text = "+$" + str(prize) + " Earned"
	
	if CurrencyManager:
		CurrencyManager.add_currency(CurrencyDefinition.CurrencyType.MONEY, prize)
	else:
		push_warning("CurrencyManager missing in MatchResultPopup!")

# Add a _ready function to guarantee your close button is connected!
func _ready() -> void:
	if not close_button.pressed.is_connected(_on_close_button_pressed):
		close_button.pressed.connect(_on_close_button_pressed)

func _on_close_button_pressed() -> void:
	queue_free()
