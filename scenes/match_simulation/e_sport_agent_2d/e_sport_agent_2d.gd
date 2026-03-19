extends CharacterBody2D
class_name ESportAgent2D

signal agent_died(victim: ESportAgent2D, killer: ESportAgent2D)
signal bomb_planted(plant_position: Vector2)
signal bomb_dropped(drop_position: Vector2)
signal bomb_defused()

@export var vision_component: VisionComponent
@export var nav_component: NavigationComponent
@export var movement_component: MovementComponent
@export var state_machine: StateMachine

@onready var visual_polygon: Polygon2D = %Polygon2D

var agent_data: ESportPlayer 
var equipped_weapon: WeaponData

var is_team_a: bool = true
var assigned_waypoint: Vector2 = Vector2.ZERO
var is_carrying_bomb: bool = false
var has_deployed_smoke: bool = false
var has_deployed_flash: bool = false

# The shared memory for our states!
var current_target: ESportAgent2D 

func _ready() -> void:
	# 1. Boot up the state machine and pass it our self-reference
	state_machine.initialize(self)
	call_deferred("_actor_setup")

func _actor_setup() -> void:
	nav_component.set_destination(assigned_waypoint)

func setup_agent(player_data: ESportPlayer, team_a: bool, target_pos: Vector2, give_bomb: bool = false, weapon: WeaponData = null) -> void:
	agent_data = player_data
	is_team_a = team_a
	assigned_waypoint = target_pos
	is_carrying_bomb = give_bomb 
	has_deployed_smoke = false 
	has_deployed_flash = false 
	
	# Equip the weapon! If none was provided, give them a default fallback.
	if weapon != null:
		equipped_weapon = weapon
	else:
		equipped_weapon = WeaponData.new() # Defaults to AK-47 stats from the script
		
	# Apply weapon weight to their movement speed!
	nav_component.max_speed = 150.0 * equipped_weapon.mobility
	
	visual_polygon.color = Color(0.2, 0.8, 0.2) if is_team_a else Color(0.8, 0.2, 0.2)
	vision_component.setup(is_team_a)

func _physics_process(delta: float) -> void:
	# 2. Tell the State Machine to run whichever state is currently active
	state_machine.physics_process(delta)

func pickup_bomb() -> void:
	is_carrying_bomb = true
	print("🎒 ", name, " picked up the dropped bomb!")
	
	# Edge Case: What if the agent who picked it up was already sitting 
	# inside the MapZone defending it? We force them to start planting!
	if state_machine.current_state.name == "StateDefend":
		state_machine.current_state.transitioned.emit(state_machine.current_state, "StatePlant")

# ==============================================================================
# OBJECTIVE LOGIC
# ==============================================================================
func retrieve_dropped_bomb(bomb_pos: Vector2) -> void:
	# Update internal memory to the dropped bomb location
	assigned_waypoint = bomb_pos
	nav_component.set_destination(bomb_pos)
	
	print("🏃 ", name, " is redirecting to retrieve the dropped bomb!")
	
	# Hijack their current state and force them to move to the new waypoint
	var current_state_name = state_machine.current_state.name
	if current_state_name in ["StateDefend", "StateIdle", "StateMove"]:
		state_machine.current_state.transitioned.emit(state_machine.current_state, "StateMove")
	
func start_defusing() -> void:
	print("🛡️ ", name, " has arrived at the bomb and is starting to defuse!")
	state_machine.current_state.transitioned.emit(state_machine.current_state, "StateDefuse")

func retake_site(bomb_pos: Vector2) -> void:
	print("🔄 ", name, " heard the bomb! Rotating to the site.")
	
	# 1. Update our internal memory and the nav component
	assigned_waypoint = bomb_pos
	nav_component.set_destination(bomb_pos)
	
	# 2. If we are currently just standing around defending an empty site, start moving!
	# (If we are in StateEngage fighting someone, we finish the fight first, 
	# and THEN StateEngage will naturally transition us back to StateMove with the new waypoint!)
	if state_machine.current_state.name == "StateDefend" or state_machine.current_state.name == "StateIdle":
		state_machine.current_state.transitioned.emit(state_machine.current_state, "StateMove")

func get_flashed() -> void:
	# Ignore the flash if we are already dead!
	if is_queued_for_deletion(): return
	
	# Force the State Machine to instantly drop what it's doing and go blind
	if state_machine.current_state:
		state_machine.current_state.transitioned.emit(state_machine.current_state, "StateBlinded")

func die(killer: ESportAgent2D = null) -> void:
	if is_carrying_bomb:
		print("⚠️ ", name, " dropped the bomb!")
		bomb_dropped.emit(global_position)
		is_carrying_bomb = false 
		
	# Pass both ourselves (the victim) and the killer to the Arena!
	agent_died.emit(self, killer)
	queue_free()

# ==============================================================================
# CLUTCH LOGIC
# ==============================================================================
func clutch_sweep(target_pos: Vector2) -> void:
	# Update our internal memory to the new target
	assigned_waypoint = target_pos
	nav_component.set_destination(target_pos)
	
	print("🕵️ ", name, " is clutching! Sweeping the map...")
	
	# If we are just sitting around defending an empty site, force us to start moving!
	if state_machine.current_state.name == "StateDefend" or state_machine.current_state.name == "StateIdle":
		state_machine.current_state.transitioned.emit(state_machine.current_state, "StateMove")

# ==============================================================================
# COMBAT AWARENESS
# ==============================================================================
func hear_shot_from(shooter: ESportAgent2D) -> void:
	# Ignore if we are dead or blind!
	if is_queued_for_deletion() or state_machine.current_state.name == "StateBlinded": return
	
	# If we are just moving/defending, or if we don't have a target yet:
	if current_target == null or state_machine.current_state.name != "StateEngage":
		print("❗ ", name, " heard bullets and turned around!")
		current_target = shooter
		
		# Instantly snap our rotation to face the shooter!
		var direction_to_shooter = global_position.direction_to(shooter.global_position)
		rotation = direction_to_shooter.angle()
		
		# Fight back!
		state_machine.current_state.transitioned.emit(state_machine.current_state, "StateEngage")
