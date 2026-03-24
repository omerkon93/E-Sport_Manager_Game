extends PanelContainer
class_name PlayerHUDPanel

@onready var name_label: Label = %PlayerNameLabel
@onready var health_bar: ProgressBar = %HealthBar

var tracked_agent: ESportAgent2D
var last_health: float = 100.0

func setup(agent: ESportAgent2D) -> void:
	tracked_agent = agent
	name_label.text = agent.agent_data.alias if agent.agent_data else "Unknown"
	
	# --- NEW: Set the progress bar max value ---
	health_bar.max_value = agent.max_health
	
	# Color code the health bar based on team
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.2, 0.8, 0.2) if agent.is_team_a else Color(0.8, 0.2, 0.2)
	health_bar.add_theme_stylebox_override("fill", sb)

func _process(_delta: float) -> void:
	if is_instance_valid(tracked_agent) and not tracked_agent.is_queued_for_deletion():
		var current_health = tracked_agent.health
		
		# If health dropped since the last frame, flash the panel red!
		if current_health < last_health:
			_flash_hurt()
			
		health_bar.value = current_health
		last_health = current_health
	else:
		# Agent is dead!
		health_bar.value = 0
		name_label.modulate = Color(0.3, 0.3, 0.3) # Gray out the name
		modulate.a = 0.5 # Make the whole panel semi-transparent
		set_process(false) # Stop processing to save performance
	
func _flash_hurt() -> void:
	var tween = create_tween()
	modulate = Color(10, 10, 10) # Overbright white/red flash
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
