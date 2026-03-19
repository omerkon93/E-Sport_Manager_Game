extends Node
class_name State

# We emit this to tell the StateMachine to switch to a different state
@warning_ignore("unused_signal")
signal transitioned(state: State, new_state_name: String)

# Every state needs to know which Agent it is controlling
var actor: ESportAgent2D

# Called exactly once when the State Machine switches TO this state
func enter() -> void:
	pass

# Called exactly once when the State Machine switches AWAY from this state
func exit() -> void:
	pass

# Replaces the Agent's _physics_process
func physics_update(_delta: float) -> void:
	pass
