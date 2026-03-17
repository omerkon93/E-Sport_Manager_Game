extends Control
class_name LiveMatchViewer

@onready var team_names_label: Label = %TeamNamesLabel
@onready var score_label: Label = %ScoreLabel
@onready var feed_label: RichTextLabel = %FeedLabel
@onready var skip_button: Button = %SkipButton # 1. Add this!

func _ready() -> void:
	MatchSimulator.match_started.connect(_on_match_started)
	MatchSimulator.round_played.connect(_on_round_played)
	MatchSimulator.match_finished.connect(_on_match_finished)
	skip_button.pressed.connect(_on_skip_pressed)

# 3. Add this new function!
func _on_skip_pressed() -> void:
	skip_button.disabled = true
	skip_button.text = "Skipping..."
	MatchSimulator.skip_requested = true # Flip the global flag!

func _on_match_started(team_a: String, team_b: String) -> void:
	team_names_label.text = "%s vs %s" % [team_a, team_b]
	score_label.text = "0 - 0"
	feed_label.text = "[center][b]--- MATCH STARTED ---[/b][/center]\n\n"

func _on_round_played(round_num: int, winner_name: String, log_text: String, score_a: int, score_b: int) -> void:
	# 1. Update the big scoreboard at the top
	score_label.text = "%d - %d" % [score_a, score_b]
	
	# 2. Figure out if we won the round so we can pick a color
	var is_my_team = false
	if GameManager.my_team != null and winner_name == GameManager.my_team.team_name:
		is_my_team = true
		
	# Pick a nice bright Hex color (Green for you, Red for the enemy)
	var color_tag = "#55ff55" if is_my_team else "#ff5555"
	
	# 3. Build the feed string with the Winner and the Score
	var header = "[b]Round %d - %s wins![/b] (Score: %d - %d)" % [round_num, winner_name, score_a, score_b]
	
	# 4. Wrap everything in the BBCode color tags and append it!
	var final_feed_text = "[color=%s]%s\n> %s[/color]\n\n" % [color_tag, header, log_text]
	
	feed_label.append_text(final_feed_text)

func _on_match_finished(_results: Dictionary) -> void:
	# The match is over! Wait one second so the player can read the final kill...
	await get_tree().create_timer(1.5).timeout
	
	# ...then delete this viewer from the screen so the Results Popup can show up!
	queue_free()
