extends Node

# ==============================================================================
# SIGNALS
# ==============================================================================
signal match_started(team_a_name: String, team_b_name: String)
signal round_played(round_num: int, winner_name: String, log_text: String, score_a: int, score_b: int)
signal match_finished(final_results: Dictionary)
signal kill_feed_event(killer_name: String, victim_name: String, killer_is_team_a: bool)
signal round_started()

# ==============================================================================
# CONSTANTS & SCENES
# ==============================================================================
const MAX_ROUNDS = 24
const MAX_WINS = 13

@export var agent_scene : PackedScene
@export var dropped_bomb_scene : PackedScene
@export var planted_bomb_scene : PackedScene

@export_group("Utility Scenes")
@export var smoke_scene: PackedScene
@export var flash_scene: PackedScene

# ==============================================================================
# COMPONENTS
# ==============================================================================
@onready var armory: MatchArmory = $MatchArmory
@onready var stats: MatchStats = $MatchStats
@onready var economy: MatchEconomy = $MatchEconomy

# ==============================================================================
# LIVE MATCH TRACKING
# ==============================================================================
var skip_requested: bool = false
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
const C4_DETONATION_TIME: float = 20.0
var is_round_over: bool = false

# ==============================================================================
# GAME LOOP
# ==============================================================================
func _process(delta: float) -> void:
	if is_bomb_planted:
		c4_timer -= delta
		if c4_timer <= 0:
			_detonate_bomb()

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
	
	# --- Initialize the Stat Ledger via Component ---
	stats.initialize_ledger(team_a, team_b)
	economy.initialize_economy(team_a, team_b)
	
	# Wait for the NavigationServer to finish booting up!
	await get_tree().physics_frame
	await get_tree().physics_frame 
	
	_start_new_round()

func _start_new_round() -> void:
	print("=======================================")
	print("🏁 STARTING ROUND ", current_round, " (Score: ", score_a, " - ", score_b, ")")
	
	living_team_a.clear()
	living_team_b.clear()
	is_bomb_planted = false
	is_round_over = false 
	
	current_arena.reset_angles()
	
	# --- TACTICAL STRATEGIES ---
	var ct_strategy = ["A", "A", "Mid", "B", "B"]
	var t_strategy = ["B", "B", "B", "B", "B"]
	
	# Spawn Team A (CT)
	for i in range(5):
		var player_data = active_team_a.active_roster[i] if active_team_a.active_roster.size() > i else null
		_spawn_single_agent(player_data, true, ct_strategy[i], false, i)
		
	# Spawn Team B (T)
	for i in range(5):
		var player_data = active_team_b.active_roster[i] if active_team_b.active_roster.size() > i else null
		var give_bomb = (i == 0)
		_spawn_single_agent(player_data, false, t_strategy[i], give_bomb, i)
	
	round_started.emit()

func _spawn_single_agent(player_data: ESportPlayer, is_team_a: bool, target_site: String, give_bomb: bool, player_index: int) -> void:	
	var agent = agent_scene.instantiate() as ESportAgent2D
	current_arena.add_child(agent)
	
	agent.global_position = current_arena.get_fixed_spawn_position(is_team_a, player_index)
	
	var target_waypoint: Vector2
	if is_team_a:
		target_waypoint = current_arena.claim_defensive_angle(target_site, agent)
	else:
		if give_bomb:
			target_waypoint = current_arena.get_site_center(target_site)
		else:
			target_waypoint = current_arena.claim_defensive_angle(target_site, agent)
	
	# 1. Buy the Main Weapon
	var current_balance = economy.get_balance(player_data)
	var assigned_weapon = armory.get_weapon_for_role(player_data, current_balance, is_team_a) 
	economy.spend_money(player_data, assigned_weapon.cost)
	
	# 2. Buy Utility with leftover cash!
	var leftover_cash = economy.get_balance(player_data)
	var utility_bought = armory.buy_utility(leftover_cash)
	economy.spend_money(player_data, utility_bought.cost)
	
	agent.setup_agent(player_data, is_team_a, target_waypoint, give_bomb, assigned_weapon)
	
	# --- NEW: Fill their pockets! ---
	agent.smokes_count = utility_bought.smokes
	agent.flashes_count = utility_bought.flashes
	
	# --- NEW: Connect the grenade signal ---
	agent.grenade_thrown.connect(_on_grenade_thrown)
	
	# 3. Build a nice string for the UI (e.g., "☁️ ⚡⚡")
	var util_string = ""
	for i in range(utility_bought.smokes): util_string += "☁️ "
	for i in range(utility_bought.flashes): util_string += "⚡ "
	
	# 4. Save to the ledger
	stats.ledger[player_data]["weapon"] = assigned_weapon.weapon_name
	stats.ledger[player_data]["utility"] = util_string.strip_edges()
	
	# 5. Setup the Agent
	agent.setup_agent(player_data, is_team_a, target_waypoint, give_bomb, assigned_weapon)
	
	# Optional: If your agent script has variables for grenades, pass them here!
	# agent.smokes = utility_bought.smokes
	# agent.flashes = utility_bought.flashes
	
	stats.ledger[player_data]["weapon"] = assigned_weapon.weapon_name
	
	agent.setup_agent(player_data, is_team_a, target_waypoint, give_bomb, assigned_weapon)
	
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
	
	if planted_bomb_scene:
		var visual_bomb = planted_bomb_scene.instantiate()
		current_arena.add_child(visual_bomb)
		visual_bomb.global_position = plant_position
		visual_bomb.add_to_group("planted_bombs")
		
	var retake_entry_point = _get_closest_entry_point(plant_position)
	for agent in living_team_a:
		if is_instance_valid(agent):
			agent.prepare_retake(retake_entry_point, plant_position)

func _on_bomb_dropped(drop_position: Vector2) -> void:
	if dropped_bomb_scene:
		print("📢 MATCH COMMAND: Bomb dropped! Ordering Ts to retrieve it.")
		var dropped_bomb = dropped_bomb_scene.instantiate()
		current_arena.add_child(dropped_bomb)
		dropped_bomb.global_position = drop_position
		dropped_bomb.add_to_group("dropped_bombs")
		
		for agent in current_arena.get_children():
			if agent is ESportAgent2D and not agent.is_queued_for_deletion():
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

func _on_bomb_picked_up(new_carrier: ESportAgent2D) -> void:
	print("📢 MATCH COMMAND: Bomb recovered. Issuing new site push!")
	var target_site = current_arena.site_a.global_position 
	
	for agent in living_team_b:
		if is_instance_valid(agent):
			if agent == new_carrier:
				agent.push_site_with_bomb(target_site)
			else:
				agent.escort_carrier(target_site)

# ==============================================================================
# COMBAT & DEATH LOGIC
# ==============================================================================
func _on_agent_died(victim: ESportAgent2D, killer: ESportAgent2D) -> void:
	# --- Tell the Stats Component to log the event ---
	stats.record_kill_event(killer, victim)
	
	if victim and victim.agent_data:
		stats.ledger[victim.agent_data]["weapon"] = "☠️"
	
	# --- Give the killer their $300! ---
	if is_instance_valid(killer) and killer.agent_data:
		economy.award_kill_bonus(killer.agent_data)
		
	# 1. Remove them from the living arrays
	if victim.is_team_a: living_team_a.erase(victim)
	else: living_team_b.erase(victim)
	
	# 2. Figure out the names for the HUD feed
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
	var spawn_a_pos = current_arena.team_a_spawn.global_position
	var dir_to_spawn = bomb_pos.direction_to(spawn_a_pos)
	var gather_point = bomb_pos + (dir_to_spawn * 300.0)
	var nav_map_rid = get_tree().root.get_world_2d().navigation_map
	return NavigationServer2D.map_get_closest_point(nav_map_rid, gather_point)

func _check_round_over() -> void:
	if living_team_a.is_empty() and not living_team_b.is_empty():
		_end_round(false)
	elif living_team_b.is_empty() and not living_team_a.is_empty():
		if not is_bomb_planted: _end_round(true)
	else:
		if living_team_a.size() == 1 and not is_round_over:
			_assign_clutch_waypoint(living_team_a[0], living_team_b)
		if living_team_b.size() == 1 and not is_round_over:
			_assign_clutch_waypoint(living_team_b[0], living_team_a)

func _assign_clutch_waypoint(clutch_agent: ESportAgent2D, enemy_team_array: Array) -> void:
	if is_bomb_planted: return
	
	var dropped_bombs = get_tree().get_nodes_in_group("dropped_bombs")
	
	if not clutch_agent.is_team_a:
		if clutch_agent.is_carrying_bomb: return 
		if dropped_bombs.size() > 0:
			clutch_agent.clutch_sweep(dropped_bombs[0].global_position)
			return
	else:
		if dropped_bombs.size() > 0:
			clutch_agent.clutch_sweep(dropped_bombs[0].global_position)
			return

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
	
	# --- NEW: Distribute Win/Loss Money! ---
	# We check for null just in case you ever implement round draws/ties
	if team_a_won != null:
		economy.award_round_end(active_team_a.active_roster, active_team_b.active_roster, team_a_won)
	
	# Check if the match is over
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
	
	# --- Save the stats before we close out! ---
	stats.commit_match_stats_to_players()
	
	var final_results = {
		"team_a": active_team_a,
		"team_b": active_team_b,
		"score_a": score_a,
		"score_b": score_b,
		"winner": active_team_a if score_a > score_b else active_team_b,
		"player_won": score_a > score_b 
	}
	match_finished.emit(final_results)

func _on_grenade_thrown(grenade_type: String, thrower: ESportAgent2D, target_pos: Vector2) -> void:
	if grenade_type == "smoke":
		_create_smoke_cloud(thrower.global_position, target_pos) 
	elif grenade_type == "flash":
		_create_flashbang(thrower.global_position, target_pos, thrower.is_team_a)

func _create_smoke_cloud(start_pos: Vector2, target_pos: Vector2) -> void:
	if smoke_scene:
		var smoke = smoke_scene.instantiate()
		current_arena.add_child(smoke)
		
		# 1. Start at the agent's hand
		smoke.global_position = start_pos 
		
		# 2. Create the trajectory animation (takes 0.6 seconds to fly)
		var tween = create_tween()
		tween.tween_property(smoke, "global_position", target_pos, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	else:
		push_error("MatchSimulator: No smoke_scene assigned!")

func _create_flashbang(start_pos: Vector2, target_pos: Vector2, thrower_is_team_a: bool) -> void:
	if flash_scene:
		var flash = flash_scene.instantiate()
		current_arena.add_child(flash)
		
		# 1. Start at the agent's hand
		flash.global_position = start_pos 
		
		# 2. Animate the throw (0.5 seconds to fly)
		var tween = create_tween()
		tween.tween_property(flash, "global_position", target_pos, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
		# 3. Wait for the grenade to land BEFORE blinding people!
		await tween.finished
		
		# --- BANG! Blind the enemies ---
		var enemies = living_team_b if thrower_is_team_a else living_team_a
		for enemy in enemies:
			if is_instance_valid(enemy):
				if enemy.global_position.distance_to(target_pos) < 300.0:
					# Just tell the enemy to flash itself!
					enemy.apply_flashbang(2.5)
	else:
		push_error("MatchSimulator: No flash_scene assigned!")

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
