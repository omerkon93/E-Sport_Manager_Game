extends Control

@onready var title_label: Label = %TitleLabel
@onready var score_label: Label = %ScoreLabel
@onready var reward_label: Label = %RewardLabel
@onready var close_button: Button = %CloseButton

# We will need your money resource to actually award the prize!
# Drag game_data/game_resources/currencies/money.tres into this in the inspector
@export var money_resource: CurrencyDefinition.CurrencyType

## This is the function we call right after the match finishes!
func display_results(results: Dictionary) -> void:
	# 1. Update the Title
	if results["player_won"]:
		title_label.text = "VICTORY!"
		title_label.modulate = Color(0.2, 0.8, 0.2) # Green text
	else:
		title_label.text = "DEFEAT!"
		title_label.modulate = Color(0.8, 0.2, 0.2) # Red text
		
	# 2. Update the Score
	score_label.text = "Your Team: %d  |  Enemy Team: %d" % [results["player_score"], results["enemy_score"]]
	
	# 3. Update the Reward and give the player their money!
	var prize: int = results["prize_money"]
	reward_label.text = "+$" + str(prize) + " Earned"
	
	# Hooking into your existing system!
	if money_resource != null and CurrencyManager:
		CurrencyManager.add_currency(money_resource, prize)
	else:
		push_warning("Money Resource missing in MatchResultPopup!")


func _on_close_button_pressed() -> void:
	# This deletes the popup from the game and frees up the memory
	queue_free()
