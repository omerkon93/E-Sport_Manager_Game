extends Node
class_name MatchStats

# Key: ESportPlayer -> Value: {"kills": 0, "deaths": 0, "damage": 0.0}
var ledger: Dictionary = {}

func initialize_ledger(team_a: ESportTeam, team_b: ESportTeam) -> void:
	ledger.clear()
	for player in team_a.active_roster:
		if player != null: 
			ledger[player] = {"kills": 0, "deaths": 0, "damage": 0.0, "weapon": "", "utility": ""}
	
	for player in team_b.active_roster:
		if player != null:
			ledger[player] = {"kills": 0, "deaths": 0, "damage": 0.0, "weapon": "", "utility": ""}
			
	print("📊 MatchStats: Ledger initialized.")

func record_kill_event(killer: ESportAgent2D, victim: ESportAgent2D) -> void:
	# 1. Log Death
	if victim and victim.agent_data and ledger.has(victim.agent_data):
		ledger[victim.agent_data]["deaths"] += 1
		
	# 2. Log Kill and Damage
	if killer and killer != victim and killer.agent_data and ledger.has(killer.agent_data):
		ledger[killer.agent_data]["kills"] += 1
		ledger[killer.agent_data]["damage"] += victim.max_health
		
		var stats = ledger[killer.agent_data]
		print("🏆 KILL FEED: %s killed %s! (K: %d, D: %d)" % [killer.name, victim.name, stats.kills, stats.deaths])

func commit_match_stats_to_players() -> void:
	for player in ledger.keys():
		var p_stats = ledger[player]
		
		# 1. Add match stats to lifetime stats
		player.lifetime_kills += p_stats.kills
		player.lifetime_deaths += p_stats.deaths
		player.lifetime_damage += p_stats.damage
		player.matches_played += 1
		
		# 2. Save the Resource file directly to the disk!
		# Godot knows exactly where the .tres file lives, so we just pass the object.
		var err = ResourceSaver.save(player)
		
		if err != OK:
			push_error("Failed to save stats for player: ", player.alias)
			
	print("💾 MatchStats: Player lifetime statistics permanently saved to disk!")
