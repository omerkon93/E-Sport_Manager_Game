extends Node

signal match_started(team_a_name: String, team_b_name: String)
signal round_played(round_num: int, winner_name: String, log_text: String, score_a: int, score_b: int)
signal match_finished(final_results: Dictionary)
signal kill_feed_event(killer_name: String, victim_name: String, killer_is_team_a: bool)
signal round_started()

const MAX_ROUNDS = 24
const MAX_WINS = 13
var skip_requested: bool = false

# --- 2D SCENES ---
# Update these paths if your scenes are saved in a different folder!
const AGENT_SCENE = preload("res://scenes/match_simulation/esport_agent_2d/esport_agent_2d.tscn")
const DROPPED_BOMB_SCENE = preload("res://scenes/match_simulation/interactables/bomb/dropped_bomb.tscn")
const PLANTED_BOMB_SCENE = preload("res://scenes/match_simulation/interactables/bomb/planted_bomb.tscn")
const WEAPON_PATHS = ["res://game_data/weapons/"]

# --- LIVE MATCH TRACKING ---
var current_arena: MatchArena2D
var active_team_a: ESportTeam
var active_team_b: ESportTeam

var score_a: int = 0
var score_b: int = 0
var current_round: int = 1

var living_team_a: Array[ESportAgent2D] = []
var living_team_b: Array[ESportAgent2D] = []

var is_bomb_planted: bool = false
var c4_timer: float = 0.0
const C4_DETONATION_TIME: float = 40.0
var is_round_over: bool = false

var armory: Dictionary = {}
var all_weapons: Dictionary = {}

func _ready() -> void:
	# 1. Automatically scan and load all WeaponData resources
	_scan_for_weapons()
	
	# 2. Map the loaded weapons to our specific Roles!
	_assign_weapons_to_roles()

func _process(delta: float) -> void:
	if is_bomb_planted:
		c4_timer -= delta
		if c4_timer <= 0:
			_detonate_bomb()

# ==============================================================================
# AUTO-LOADER
# ==============================================================================
func _scan_for_weapons() -> void:
	for path in WEAPON_PATHS:
		_load_dir_recursive(path)
	print("🔫 MatchSimulator: Automatically loaded %d weapons." % all_weapons.size())

func _load_dir_recursive(path: String) -> void:
	var dir = DirAccess.open(path)
	if dir == null:
		print("❌ MatchSimulator Error: Could not open path: ", path)
		return
		
	# 1. Grab all files in this folder automatically!
	for file_name in dir.get_files():
		if file_name.ends_with(".tres") or file_name.ends_with(".res"):
			var full_path = path + "/" + file_name
			var resource = load(full_path)
			
			if resource is WeaponData:
				all_weapons[resource.weapon_name.to_upper()] = resource
				
	# 2. Recursively dig into all sub-folders automatically!
	for dir_name in dir.get_directories():
		_load_dir_recursive(path + "/" + dir_name)

# ==============================================================================
# ROLE MAPPING
# ==============================================================================
func _assign_weapons_to_roles() -> void:
	# We use .get() here. If a weapon file is missing, it safely falls back to a blank WeaponData!
	var fallback_weapon = WeaponData.new()
	
	# Try to find the AK-47 to use as our absolute baseline default
	var default_rifle = all_weapons.get("AK-47", fallback_weapon)
	
	armory["DEFAULT"] = default_rifle
	armory["AWPER"] = all_weapons.get("AWP", default_rifle)
	armory["ENTRY"] = all_weapons.get("MAC-10", default_rifle)
	armory["SUPPORT"] = all_weapons.get("M4A4", default_rifle)

# ==============================================================================
# LIVE 2D MATCH LOOP
# ==============================================================================
# ==============================================================================
# LIVE 2D MATCH LOOP
# ==============================================================================
func play_live_match(arena_instance: MatchArena2D, team_a: ESportTeam, team_b: ESportTeam) -> void:
	skip_requested = false
	current_arena = arena_instance
	active_team_a = team_a
	active_team_b = team_b
	
	score_a = 0
	score_b = 0
	current_round = 1
	
	match_started.emit(team_a.team_name, team_b.team_name)
	print("⚔️ 2D MATCH START: ", team_a.team_name, " vs ", team_b.team_name)
	
	# Wait for the NavigationServer to finish booting up! ---
	await get_tree().physics_frame
	await get_tree().physics_frame # Waiting two frames guarantees 100% safety
	
	_start_new_round()

func _start_new_round() -> void:
	print("=======================================")
	print("🏁 STARTING ROUND ", current_round, " (Score: ", score_a, " - ", score_b, ")")
	
	living_team_a.clear()
	living_team_b.clear()
	is_bomb_planted = false
	is_round_over = false 
	
	
	# Clean up the Arena's angle dictionary from the last round!
	current_arena.reset_angles()
	
	# --- TACTICAL STRATEGIES ---
	# CT Side: Standard 2-1-2 Split
	var ct_strategy = ["A", "A", "Mid", "B", "B"]
	
	# T Side: "Rush B!" (All 5 players run to B)
	var t_strategy = ["B", "B", "B", "B", "B"]
	
	# Spawn Team A (CT)
	for i in range(5):
		var player_data = active_team_a.active_roster[i] if active_team_a.active_roster.size() > i else null
		# We now pass the string ("A", "Mid", etc) and the index 'i'
		_spawn_single_agent(player_data, true, ct_strategy[i], false, i)
		
	# Spawn Team B (T)
	for i in range(5):
		var player_data = active_team_b.active_roster[i] if active_team_b.active_roster.size() > i else null
		var give_bomb = (i == 0)
		_spawn_single_agent(player_data, false, t_strategy[i], give_bomb, i)
	
	round_started.emit()


func _spawn_single_agent(player_data: ESportPlayer, is_team_a: bool, target_site: String, give_bomb: bool, player_index: int) -> void:	
	# 1. Instantiate the agent FIRST so they exist in memory
	var agent = AGENT_SCENE.instantiate() as ESportAgent2D
	current_arena.add_child(agent)
	
	# 2. Put them at their specific, fixed spawn point!
	agent.global_position = current_arena.get_fixed_spawn_position(is_team_a, player_index)
	
	# 3. Ask the Arena where this agent should go
	var target_waypoint: Vector2
	
	if is_team_a:
		# CTs always claim hiding spots and defensive angles
		target_waypoint = current_arena.claim_defensive_angle(target_site, agent)
	else:
		if give_bomb:
			# ONLY the bomb carrier pushes the exact center (Area2D) to plant!
			target_waypoint = current_arena.get_site_center(target_site)
			print("💣 PLANTER: ", agent.name, " is pushing to the center of ", target_site)
		else:
			# The rest of the T-side pushes up to take defensive cover angles
			target_waypoint = current_arena.claim_defensive_angle(target_site, agent)
			print("🛡️ ENTRY: ", agent.name, " is taking a cover angle at ", target_site)
	
	# Determine what gun to give them based on their Role!
	var assigned_weapon = armory.get("DEFAULT")
	
	if player_data != null:
		var role_string: String = ESportPlayer.PlayerRole.keys()[player_data.preferred_role].to_upper()
		if armory.has(role_string):
			assigned_weapon = armory[role_string]
	
	# Pass all the data into the agent's setup
	agent.setup_agent(player_data, is_team_a, target_waypoint, give_bomb, assigned_weapon)
	
	# Connect signals
	agent.agent_died.connect(_on_agent_died)
	agent.bomb_planted.connect(_on_bomb_planted)
	agent.bomb_dropped.connect(_on_bomb_dropped)
	agent.bomb_defused.connect(_on_bomb_defused)
	agent.bomb_picked_up.connect(_on_bomb_picked_up)
	
	if is_team_a: living_team_a.append(agent)
	else: living_team_b.append(agent)

# ==============================================================================
# BOMB & WIN CONDITIONS
# ==============================================================================
func _on_bomb_planted(plant_position: Vector2) -> void:
	is_bomb_planted = true
	c4_timer = C4_DETONATION_TIME
	print("⏱️ C4 Armed! 40 seconds to detonation.")
	
	# 1. Spawn the visual bomb (already have this)
	if PLANTED_BOMB_SCENE:
		var visual_bomb = PLANTED_BOMB_SCENE.instantiate()
		current_arena.add_child(visual_bomb)
		visual_bomb.global_position = plant_position
		visual_bomb.add_to_group("planted_bombs")
		
	# 2. Tell the CTs to BEGIN THE RETAKE
	# Instead of just running to the site center, we tell them to GATHER at the entrance.
	var retake_entry_point = _get_closest_entry_point(plant_position)
	
	for agent in living_team_a:
		if is_instance_valid(agent):
			# New command: Prepare for retake
			agent.prepare_retake(retake_entry_point, plant_position)

func _on_bomb_dropped(drop_position: Vector2) -> void:
	if DROPPED_BOMB_SCENE:
		print("📢 MATCH COMMAND: Bomb dropped! Ordering Ts to retrieve it.")
		
		# 1. Spawn the physical bomb in the world
		var dropped_bomb = DROPPED_BOMB_SCENE.instantiate()
		current_arena.add_child(dropped_bomb)
		dropped_bomb.global_position = drop_position
		dropped_bomb.add_to_group("dropped_bombs")
		
		# 2. Loop through the agents in the arena to give the order
		for agent in current_arena.get_children():
			if agent is ESportAgent2D and not agent.is_queued_for_deletion():
				# Assuming 'is_team_a' == false means they are Terrorists
				if not agent.is_team_a: 
					agent.retrieve_dropped_bomb(drop_position)

func _on_bomb_defused() -> void:
	is_bomb_planted = false
	print("🛡️ Team A successfully defused the bomb!")
	_end_round(true)

func _detonate_bomb() -> void:
	is_bomb_planted = false
	print("💥 KABOOM! The bomb detonated!")
	_end_round(false)

# ==============================================================================
# BOMB RECOVERY & PUSH LOGIC
# ==============================================================================
func _on_bomb_picked_up(new_carrier: ESportAgent2D) -> void:
	var carrier_name = new_carrier.agent_data.alias if new_carrier.agent_data else "Unknown"
	print("📢 MATCH COMMAND: Bomb recovered by ", carrier_name, ". Issuing new site push!")
	
	# 1. Decide which site to push (For now, let's just pick Site A, 
	# but you can upgrade this later to pick the closest site or safest site)
	var target_site = current_arena.site_a.global_position 
	
	# 2. Issue new orders to all living T-Side agents
	for agent in living_team_b:
		if is_instance_valid(agent):
			if agent == new_carrier:
				# The new carrier's sole purpose is to reach the site and trigger StatePlant
				agent.push_site_with_bomb(target_site)
			else:
				# The rest of the team needs to cancel their retrieval state 
				# and either escort the carrier or push the site
				agent.escort_carrier(target_site)

func _on_agent_died(victim: ESportAgent2D, killer: ESportAgent2D) -> void:
	# 1. Remove them from the living arrays
	var was_team_a = victim.is_team_a
	if was_team_a: living_team_a.erase(victim)
	else: living_team_b.erase(victim)
	
	# 2. Figure out the names! (Fallback to "Unknown" if data is missing)
	var victim_name = victim.agent_data.alias if victim.agent_data else "Unknown"
	var killer_name = "The Zone"
	var killer_is_team_a = false
	
	if is_instance_valid(killer):
		killer_name = killer.agent_data.alias if killer.agent_data else "Unknown"
		killer_is_team_a = killer.is_team_a
		
	# 3. Shout the kill to the HUD!
	kill_feed_event.emit(killer_name, victim_name, killer_is_team_a)
		
	_check_round_over()

func _get_closest_entry_point(bomb_pos: Vector2) -> Vector2:
	# 1. Realistically, you could add "EntryMarkers" to your Arena scene and find the closest one.
	# 2. For now, let's just pick a point between the bomb and the CT Spawn!
	var spawn_a_pos = current_arena.team_a_spawn.global_position
	
	# Get direction from bomb to CT spawn
	var dir_to_spawn = bomb_pos.direction_to(spawn_a_pos)
	
	# Set a "Gather Point" 300 pixels back from the bomb
	var gather_point = bomb_pos + (dir_to_spawn * 300.0)
	
	# Make sure the gather point is actually walkable
	var nav_map_rid = get_tree().root.get_world_2d().navigation_map
	return NavigationServer2D.map_get_closest_point(nav_map_rid, gather_point)

func _check_round_over() -> void:
	if living_team_a.is_empty() and not living_team_b.is_empty():
		_end_round(false)
	elif living_team_b.is_empty() and not living_team_a.is_empty():
		if not is_bomb_planted: _end_round(true)
	else:
		# --- NEW: CLUTCH DETECTION ---
		# If the round is still going, check if anyone is the last player alive!
		if living_team_a.size() == 1 and not is_round_over:
			_assign_clutch_waypoint(living_team_a[0], living_team_b)
			
		if living_team_b.size() == 1 and not is_round_over:
			_assign_clutch_waypoint(living_team_b[0], living_team_a)

func _assign_clutch_waypoint(clutch_agent: ESportAgent2D, enemy_team_array: Array) -> void:
	# 1. If the bomb is already planted, our existing retake_site() logic handles this!
	if is_bomb_planted: return
	
	# 2. Check for a dropped bomb
	var dropped_bombs = get_tree().get_nodes_in_group("dropped_bombs")
	
	if not clutch_agent.is_team_a:
		# T-Side Logic: If I have the bomb, keep going to the site to plant it!
		if clutch_agent.is_carrying_bomb: return 
		
		# T-Side Logic: If the bomb is on the ground, I MUST go recover it!
		if dropped_bombs.size() > 0:
			clutch_agent.clutch_sweep(dropped_bombs[0].global_position)
			return
	else:
		# CT-Side Logic: If the bomb is dropped, I should go guard it to stop the Ts from getting it!
		if dropped_bombs.size() > 0:
			clutch_agent.clutch_sweep(dropped_bombs[0].global_position)
			return

	# 3. If there is no bomb action, hunt down the nearest remaining enemy!
	if enemy_team_array.size() > 0:
		var nearest_enemy = enemy_team_array[0]
		var shortest_dist = clutch_agent.global_position.distance_to(nearest_enemy.global_position)
		
		for enemy in enemy_team_array:
			if is_instance_valid(enemy):
				var dist = clutch_agent.global_position.distance_to(enemy.global_position)
				if dist < shortest_dist:
					nearest_enemy = enemy
					shortest_dist = dist
					
		if is_instance_valid(nearest_enemy):
			clutch_agent.clutch_sweep(nearest_enemy.global_position)

func _end_round(team_a_won) -> void:
	if is_round_over: return
	
	is_round_over = true
	is_bomb_planted = false
	
	var winner_name = ""
	if team_a_won != null:
		if team_a_won:
			score_a += 1
			winner_name = active_team_a.team_name
			print("🏆 ", winner_name, " wins Round ", current_round, "!")
		else:
			score_b += 1
			winner_name = active_team_b.team_name
			print("🏆 ", winner_name, " wins Round ", current_round, "!")
			
	round_played.emit(current_round, winner_name, "Round Complete!", score_a, score_b)
	
	if score_a >= MAX_WINS or score_b >= MAX_WINS:
		_end_match()
		return
		
	current_round += 1
	await get_tree().create_timer(2.0).timeout
	_cleanup_and_restart()

func _cleanup_and_restart() -> void:
	for agent in living_team_a:
		if is_instance_valid(agent): agent.queue_free()
	for agent in living_team_b:
		if is_instance_valid(agent): agent.queue_free()
		
	for bomb in get_tree().get_nodes_in_group("dropped_bombs"):
		if is_instance_valid(bomb): bomb.queue_free()
	for bomb in get_tree().get_nodes_in_group("planted_bombs"):
		if is_instance_valid(bomb): bomb.queue_free()
		
	for smoke in get_tree().get_nodes_in_group("smoke_clouds"):
		if is_instance_valid(smoke): smoke.queue_free()
	for nade in get_tree().get_nodes_in_group("thrown_smokes"):
		if is_instance_valid(nade): nade.queue_free()
	for flash in get_tree().get_nodes_in_group("thrown_flashes"):
		if is_instance_valid(flash): flash.queue_free()
		
	_start_new_round()

func _end_match() -> void:
	print("=======================================")
	print("🎉 MATCH FINISHED! FINAL SCORE: ", score_a, " - ", score_b)
	
	var final_results = {
		"team_a": active_team_a,
		"team_b": active_team_b,
		"score_a": score_a,
		"score_b": score_b,
		"winner": active_team_a if score_a > score_b else active_team_b,
		"player_won": score_a > score_b 
	}
	match_finished.emit(final_results)

# ==============================================================================
# QUICK SIM MATCH (Instant Resolution)
# ==============================================================================
func quick_simulate_match(team_a: ESportTeam, team_b: ESportTeam) -> Dictionary:
	var sim_score_a = 0
	var sim_score_b = 0
	
	var power_a = _calculate_team_power(team_a)
	var power_b = _calculate_team_power(team_b)
	var total_power = power_a + power_b
	
	for i in range(1, MAX_ROUNDS + 1):
		if randf() * total_power <= power_a:
			sim_score_a += 1
		else:
			sim_score_b += 1
			
		if sim_score_a >= MAX_WINS or sim_score_b >= MAX_WINS:
			break
			
	return {
		"team_a": team_a,
		"team_b": team_b,
		"score_a": sim_score_a,
		"score_b": sim_score_b,
		"winner": team_a if sim_score_a > sim_score_b else team_b,
		"player_won": sim_score_a > sim_score_b 
	}
	
func _calculate_team_power(team: ESportTeam) -> float:
	var total_power = 0.0
	for player in team.active_roster:
		if player != null:
			total_power += player.aim 
	return max(total_power, 1.0)
