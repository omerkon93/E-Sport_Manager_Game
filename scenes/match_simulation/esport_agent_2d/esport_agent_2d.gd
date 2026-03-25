extends CharacterBody2D
class_name ESportAgent2D

# --- Signals ---
signal agent_died(victim: ESportAgent2D, killer: ESportAgent2D)
signal bomb_picked_up(new_carrier: ESportAgent2D)
signal bomb_dropped(drop_position: Vector2)
@warning_ignore("unused_signal")
signal bomb_planted(plant_position: Vector2) # Called from StatePlant
@warning_ignore("unused_signal")
signal bomb_defused() # Called from StateDefuse
signal grenade_thrown(grenade_type: String, thrower: Node2D, target_pos: Vector2)

# --- Components ---
@export_group("Components")
@export var vision_component: VisionComponent
@export var nav_component: NavigationComponent
@export var movement_component: MovementComponent
@export var state_machine: StateMachine

@export_group("Inventory")
var smokes_count: int = 0
var flashes_count: int = 0
var is_flashed: bool = false # We will use this later to lower their aim!

# --- Visuals & Data ---
@onready var visual_polygon: Polygon2D = %Polygon2D
var agent_data: ESportPlayer 
var equipped_weapon: WeaponData

# --- Combat & Health ---
var health: float = 100.0
var max_health: float = 100.0
var current_target: ESportAgent2D 

# --- Match State ---
var is_team_a: bool = true
var assigned_waypoint: Vector2 = Vector2.ZERO
var mission_waypoint: Vector2 = Vector2.ZERO # --- Long-Term Memory ---
var is_carrying_bomb: bool = false

# --- Utility & Retake ---
var has_deployed_smoke: bool = false
var has_deployed_flash: bool = false
var _is_retaking: bool = false
var _final_bomb_pos: Vector2 = Vector2.ZERO

# ==============================================================================
# INITIALIZATION
# ==============================================================================

func _ready() -> void:
	state_machine.initialize(self)
	call_deferred("_actor_setup")

func _actor_setup() -> void:
	nav_component.set_destination(assigned_waypoint)

func setup_agent(player_data: ESportPlayer, team_a: bool, target_pos: Vector2, give_bomb: bool = false, weapon: WeaponData = null) -> void:
	agent_data = player_data
	is_team_a = team_a
	assigned_waypoint = target_pos
	mission_waypoint = target_pos # --- NEW: Memorize initial order! ---
	is_carrying_bomb = give_bomb 
	has_deployed_smoke = false 
	has_deployed_flash = false 
	
	if weapon != null:
		equipped_weapon = weapon
	else:
		equipped_weapon = WeaponData.new()
		
	nav_component.max_speed = 150.0 * equipped_weapon.mobility
	visual_polygon.color = Color(0.2, 0.8, 0.2) if is_team_a else Color(0.8, 0.2, 0.2)
	vision_component.setup(is_team_a)

func _physics_process(delta: float) -> void:
	state_machine.physics_process(delta)

# ==============================================================================
# DAMAGE & DEATH
# ==============================================================================

func take_damage(amount: float, shooter: ESportAgent2D) -> void:
	if is_queued_for_deletion() or health <= 0: return
	health -= amount
	print("🩸 ", name, " took ", amount, " damage! (Health: ", health, ")")
	
	# --- Instantly react to the person shooting us! ---
	hear_shot_from(shooter)
	
	if health <= 0:
		die(shooter)

func die(killer: ESportAgent2D = null) -> void:
	health = 0.0 
	if is_carrying_bomb:
		print("⚠️ ", name, " dropped the bomb!")
		bomb_dropped.emit(global_position)
		is_carrying_bomb = false 
		
	agent_died.emit(self, killer)
	queue_free()

func apply_flashbang(duration: float) -> void:
	is_flashed = true
	modulate = Color(2, 2, 2) # Glow white
	
	# Create a tween bound to this specific agent
	var tween = create_tween()
	tween.tween_interval(duration) # Wait for 2.5 seconds
	
	# When the wait is over, reset everything
	tween.tween_callback(func():
		is_flashed = false
		modulate = Color(1, 1, 1)
	)
	
# ==============================================================================
# OBJECTIVE & RETAKE LOGIC
# ==============================================================================

func _redirect_agent(target_pos: Vector2, log_message: String) -> void:
	assigned_waypoint = target_pos
	mission_waypoint = target_pos # --- NEW: Memorize the new order! ---
	nav_component.set_destination(target_pos)
	
	print(log_message)
	
	var current_state_name = state_machine.current_state.name
	if current_state_name in ["StateDefend", "StateIdle", "StateMove"]:
		state_machine.current_state.transitioned.emit(state_machine.current_state, "StateMove")

func pickup_bomb() -> void:
	is_carrying_bomb = true
	print("🎒 ", name, " picked up the dropped bomb!")
	bomb_picked_up.emit(self)
	if state_machine.current_state.name == "StateDefend":
		state_machine.current_state.transitioned.emit(state_machine.current_state, "StatePlant")

func retrieve_dropped_bomb(bomb_pos: Vector2) -> void:
	_redirect_agent(bomb_pos, "🏃 " + name + " is redirecting to retrieve the dropped bomb!")

func push_site_with_bomb(target_pos: Vector2) -> void:
	_redirect_agent(target_pos, "💣 " + name + " has the bomb and is pushing the site!")

func escort_carrier(target_pos: Vector2) -> void:
	_redirect_agent(target_pos, "🛡️ " + name + " is escorting the carrier!")

func retake_site(bomb_pos: Vector2) -> void:
	_redirect_agent(bomb_pos, "🔄 " + name + " is rotating to the site.")

func start_defusing() -> void:
	print("🛡️ ", name, " is starting to defuse!")
	state_machine.current_state.transitioned.emit(state_machine.current_state, "StateDefuse")

func prepare_retake(entry_pos: Vector2, bomb_pos: Vector2) -> void:
	_is_retaking = true
	_final_bomb_pos = bomb_pos
	_redirect_agent(entry_pos, "🛡️ " + name + " is preparing for site retake.")

func execute_retake() -> void:
	_redirect_agent(_final_bomb_pos, "⚔️ " + name + " is EXECUTING the retake!")

# ==============================================================================
# UTILITY & COMBAT AWARENESS
# ==============================================================================
## Logic for throwing a smoke grenade (usually by Ts to block sightlines)
func throw_smoke_at_target(target_pos: Vector2, smoke_scene: PackedScene) -> void:
	if not smoke_scene or has_deployed_smoke: return
	
	has_deployed_smoke = true
	var nade = smoke_scene.instantiate()
	get_parent().add_child(nade)
	
	nade.global_position = global_position
	
	# Smokes are heavy! We throw them toward the target with a bit less speed (540.0)
	var throw_dir = global_position.direction_to(target_pos)
	nade.velocity = throw_dir * 540.0
	
	print("💨 %s: deployed tactical smoke toward site!" % name)

## Logic for throwing a flash grenade (usually by CTs to retake planted site)
func throw_flashbang_at_target(target_pos: Vector2, flash_scene: PackedScene) -> void:
	if not flash_scene: return
	has_deployed_flash = true
	var flash = flash_scene.instantiate()
	get_parent().add_child(flash)
	flash.global_position = global_position
	var throw_dir = global_position.direction_to(target_pos)
	flash.velocity = throw_dir * 800.0
	print("⚡ %s: throwing tactical flash at site!" % name)

func get_flashed() -> void:
	if is_queued_for_deletion(): return
	if state_machine.current_state:
		state_machine.current_state.transitioned.emit(state_machine.current_state, "StateBlinded")

func hear_shot_from(shooter: ESportAgent2D) -> void:
	if is_queued_for_deletion() or state_machine.current_state.name == "StateBlinded": return
	if shooter.is_team_a == self.is_team_a: return
	
	if current_target == null or state_machine.current_state.name != "StateEngage":
		# Instantly snap our rotation to face the sound!
		rotation = global_position.direction_to(shooter.global_position).angle()
		
		# --- THE FIX: Check for walls before fighting! ---
		if has_line_of_sight(shooter):
			print("❗ ", name, " heard gunfire, SAW the enemy, and engaged!")
			current_target = shooter
			state_machine.current_state.transitioned.emit(state_machine.current_state, "StateEngage")
		else:
			print("👂 ", name, " heard gunfire behind a wall. Staying on mission.")
			# Optional: You could make them investigate by calling:
			# _redirect_agent(shooter.global_position, "🕵️ Investigating sound...")

func clutch_sweep(target_pos: Vector2) -> void:
	_redirect_agent(target_pos, "🕵️ " + name + " is clutching!")

# ==============================================================================
# VISION & SENSES
# ==============================================================================
func has_line_of_sight(target: ESportAgent2D) -> bool:
	if not is_instance_valid(target): return false
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, target.global_position)
	
	# Ignore both the shooter and the target so the ray doesn't get stuck on their bodies
	query.exclude = [self.get_rid(), target.get_rid()]
	
	# NOTE: If your walls are on a specific collision layer (e.g., Layer 1), 
	# you can set query.collision_mask = 1 here.
	
	var result = space_state.intersect_ray(query)
	
	# If the ray hit ANYTHING (like a wall), the line of sight is blocked!
	if result:
		return false
		
	# If it hit nothing, the path is clear!
	return true
