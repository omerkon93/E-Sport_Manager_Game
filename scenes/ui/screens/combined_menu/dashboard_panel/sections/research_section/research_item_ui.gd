extends PanelContainer
class_name ResearchItemUI

@onready var title_label: Label = %TechTitleLabel
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var time_label: Label = %TimeRemainingLabel
@onready var info_button: ItemInfoButton = %ItemInfoButton

var tech_id: String = ""

#func setup(item: GameItem, current_time: float, total_time: float) -> void:
	#tech_id = item.id
	#title_label.text = "Researching: " + item.display_name
	#progress_bar.max_value = total_time
	#progress_bar.value = current_time
	#
	#var remaining_minutes = int(total_time - current_time)
	#time_label.text = TimeManager.format_duration_in_hours(remaining_minutes) + " left"
	#
	#if info_button:
		#info_button.setup(item.display_name, item.description)

func update_progress(current_minutes: float, total_minutes: float) -> void:
	progress_bar.max_value = total_minutes
	progress_bar.value = current_minutes
	
	var remaining_minutes = int(total_minutes - current_minutes)
	time_label.text = TimeManager.format_duration_in_hours(remaining_minutes) + " left"
