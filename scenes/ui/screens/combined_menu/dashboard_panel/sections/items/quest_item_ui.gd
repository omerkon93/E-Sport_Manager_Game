extends PanelContainer
class_name QuestItemUI

# --- NODES ---
@onready var title_label: Label = %TitleLabel
@onready var desc_label: RichTextLabel = %DescLabel
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var progress_label: Label = %ProgressLabel

# --- STATE ---
var quest_id: String = ""

func setup(quest: QuestData) -> void:
	quest_id = quest.id
	title_label.text = quest.title
	desc_label.text = quest.description
	
	# THE FIX: Check if we actually have an objective amount!
	if quest.required_amount <= 0:
		# Hide the progress UI completely
		progress_bar.visible = false
		progress_label.visible = false
	else:
		# Show them and set them up normally
		progress_bar.visible = true
		progress_label.visible = true
		progress_bar.max_value = quest.required_amount
		update_progress(0, quest.required_amount)

func update_progress(current: int, required: int) -> void:
	# SAFETY CHECK: If this quest doesn't use numbers, ignore updates
	if required <= 0:
		return
		
	progress_bar.value = current
	progress_label.text = str(current) + " / " + str(required)
	
	# Optional: Add a little juice when progress is made
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.02, 1.02), 0.1)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)
