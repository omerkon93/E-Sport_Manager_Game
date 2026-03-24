extends Node
class_name StateMachine

@export var initial_state: State
var current_state: State
var states: Dictionary = {}
var actor: ESportAgent2D # --- ADD THIS REFERENCE ---

func initialize(_actor: ESportAgent2D) -> void:
	self.actor = _actor # Store the actor reference
	
	for child in get_children():
		if child is State:
			states[child.name] = child
			child.actor = actor
			# Connect the signal (ensure your State class defines this signal!)
			child.transitioned.connect(_on_child_transition)
			
	if initial_state:
		current_state = initial_state
		current_state.enter()

func physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func _on_child_transition(state: State, new_state_name: String) -> void:
	if state != current_state:
		return
		
	var new_state = states.get(new_state_name)
	
	if not new_state:
		push_warning("⚠️ State Machine missing state: ", new_state_name)
		return
	
	# Now 'actor.name' will work because we added the variable above!
	print("🤖 %s: %s -> %s" % [actor.name, current_state.name, new_state.name])
	
	current_state.exit()
	current_state = new_state
	current_state.enter()
