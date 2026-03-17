extends ColorRect

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
	if results.get("player_won", false):
		title_label.text = "VICTORY!"
		title_label.modulate = Color(0.2, 0.8, 0.2) # Green text
	else:
		title_label.text = "DEFEAT!"
		title_label.modulate = Color(0.8, 0.2, 0.2) # Red text
		
	# 2. Update the Score (Using the new keys from the Simulator!)
	score_label.text = "Your Team: %d  |  Enemy Team: %d" % [results["score_a"], results["score_b"]]
	
	# 3. Update the Reward (With a safe fallback for MVP testing)
	# If the simulator doesn't provide prize_money, default to 1000 for a win and 250 for a loss
	var default_prize = 1000 if results.get("player_won", false) else 250
	var prize: int = results.get("prize_money", default_prize)
	
	reward_label.text = "+$" + str(prize) + " Earned"
	
	# Hooking into your existing system!
	if money_resource != null and CurrencyManager:
		CurrencyManager.add_currency(money_resource, prize)
	else:
		push_warning("Money Resource missing in MatchResultPopup!")


func _on_close_button_pressed() -> void:
	# This deletes the popup from the game and frees up the memory
	queue_free()
