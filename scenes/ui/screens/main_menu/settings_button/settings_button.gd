extends Button

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	# Just shout into the void that someone wants the settings open!
	SignalBus.open_settings_requested.emit()
