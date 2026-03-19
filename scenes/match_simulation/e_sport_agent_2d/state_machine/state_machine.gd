extends Node
class_name StateMachine

@export var initial_state: State
var current_state: State

# We call this from the Agent's _ready() function to boot up the machine
func initialize(actor: ESportAgent2D) -> void:
	# Loop through all child nodes (which will be our States)
	for child in get_children():
		if child is State:
			child.actor = actor
			# Listen for when a state says "I'm done, switch to X!"
			child.transitioned.connect(_on_child_transition)
			
	if initial_state:
		current_state = initial_state
		current_state.enter()

# The Agent passes its physics tick down into the machine
func physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

# The handler that swaps the active state
func _on_child_transition(state: State, new_state_name: String) -> void:
	if state != current_state:
		return
		
	var new_state = get_node_or_null(new_state_name)
	if not new_state:
		push_warning("State Machine tried to transition to a state that doesn't exist: ", new_state_name)
		return
		
	current_state.exit()
	current_state = new_state
	current_state.enter()
