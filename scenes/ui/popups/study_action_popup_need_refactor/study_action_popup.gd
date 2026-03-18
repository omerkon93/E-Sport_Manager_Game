extends ConfirmationDialog
class_name StudyActionPopup

@onready var time_spinbox: SpinBox = %TimeSpinBox
@onready var stats_label: RichTextLabel = %DialogStatsLabel

# We store a reference to whichever button clicked us!
var active_button: ActionButton = null

func _ready() -> void:
	# 1. Listen for any button asking for the popup
	SignalBus.study_dialog_requested.connect(_on_dialog_requested)
	
	# 2. Wire up the internal popup signals
	time_spinbox.value_changed.connect(_on_spinbox_changed)
	confirmed.connect(_on_confirmed)

func _on_dialog_requested(button: ActionButton) -> void:
	active_button = button
	title = "Study " + button.action_data.display_name
	
	# Set the spinbox to 1 hour (or the minimum time cost)
	time_spinbox.value = max(1, roundi(float(button.action_data.effective_time_cost) / 60.0))
	_on_spinbox_changed(time_spinbox.value)
	
	popup_centered()

func _on_spinbox_changed(new_val: float) -> void:
	if active_button:
		var requested_chunks = ceili(new_val)
		# We ask the button to generate the text based on its own local costs/rewards!
		stats_label.text = active_button._generate_stats_text(requested_chunks, true)

func _on_confirmed() -> void:
	if active_button:
		var requested_minutes = int(time_spinbox.value * 60)
		# Tell the button to run its chunking loop!
		active_button._execute_study_action(requested_minutes)
