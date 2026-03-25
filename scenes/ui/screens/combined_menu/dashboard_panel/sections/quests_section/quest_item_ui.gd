extends PanelContainer
class_name QuestItemUI

@onready var title_label: Label = %TitleLabel
@onready var desc_label: RichTextLabel = %DescLabel
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var progress_label: Label = %ProgressLabel
@onready var info_button: ItemInfoButton = %ItemInfoButton

var quest_id: String = ""
var current_quest_data: QuestData # Keep a reference to calculate totals

func setup(quest: QuestData) -> void:
	quest_id = quest.id
	current_quest_data = quest
	title_label.text = quest.title
	desc_label.text = quest.description
	
	if info_button:
		info_button.setup(quest.title, quest.description)
		
	# Setup will now rely on update_progress to draw the initial state
	update_progress({})

# Now takes the Dictionary of progress instead of two ints!
func update_progress(progress_dict: Dictionary) -> void:
	if not current_quest_data: return
	
	# 1. Get the formatted multi-line text from the QuestData resource
	var objective_text = current_quest_data.get_objective_text(progress_dict)
	
	if objective_text == "":
		progress_bar.visible = false
		progress_label.visible = false
		return
		
	progress_bar.visible = true
	progress_label.visible = true
	progress_label.text = objective_text
	
	# 2. Calculate totals for the single Progress Bar
	var total_required: int = 0
	var total_current: int = 0
	
	for action in current_quest_data.target_actions:
		var req = current_quest_data.target_actions[action]
		var cur = progress_dict.get(action.id, 0)
		
		total_required += req
		# Clamp the current value so over-achieving doesn't break the progress bar percentage
		total_current += mini(cur, req) 
		
	progress_bar.max_value = total_required
	progress_bar.value = total_current
	
	# Optional: Add a little juice when progress is made (only if progress > 0 so it doesn't bounce on load)
	if total_current > 0:
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.02, 1.02), 0.1)
		tween.tween_property(self, "scale", Vector2.ONE, 0.1)
