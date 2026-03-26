extends Node

const AGENT_DIRECTORY = "res://game_data/entities/players/free_agents/"
var available_agents: Array[ESportPlayer] = []

func _ready():
	add_to_group("persist")
	_scan_for_agents()

# ==============================================================================
# PUBLIC API (Database Queries & Modification Only)
# ==============================================================================
func is_agent_available(agent: ESportPlayer) -> bool:
	return available_agents.has(agent)

func remove_agent(agent: ESportPlayer) -> void:
	available_agents.erase(agent)

# --- The actual transaction logic ---
func buy_agent(team: ESportTeam, agent: ESportPlayer) -> bool:
	if not is_agent_available(agent): return false
		
	if team.can_afford(agent.hiring_cost):
		team.spend_budget(agent.hiring_cost)
		team.hire_player(agent) 
		remove_agent(agent)     
		
		SignalBus.market_updated.emit()
		
		return true
	return false

# ==============================================================================
# DYNAMIC GENERATION (Weekly Rookies)
# ==============================================================================
func generate_weekly_rookies(amount: int) -> void:
	var names = ["Flick", "Zero", "Ghost", "Neo", "Viper", "Ice", "Static", "Clutch"]
	var suffixes = ["Shot", "God", "King", "Strike", "Boy", "Snipe", "FPS", "Pro"]
	
	for i in range(amount):
		var rookie = ESportPlayer.new()
		
		# Give them a random identity
		rookie.alias = names.pick_random() + suffixes.pick_random() + str(randi_range(10, 99))
		rookie.age = randi_range(16, 19) # Young rookies!
		rookie.preferred_role = randi() % ESportPlayer.PlayerRole.size()
		
		# Generate stats (slightly lower than pros, but with potential)
		rookie.aim = randi_range(30, 75)
		rookie.game_sense = randi_range(20, 60)
		rookie.teamwork = randi_range(30, 70)
		
		# Calculate their cost based on how good their stats rolled
		var total_stats = rookie.aim + rookie.game_sense + rookie.teamwork
		rookie.hiring_cost = int(total_stats * randf_range(8.0, 12.0)) 
		
		# Fully rested
		rookie.current_energy = rookie.max_energy
		rookie.current_focus = rookie.max_focus
		
		available_agents.append(rookie)
		print("🌟 MarketManager: New rookie scouted - ", rookie.alias)

	# Tell the Shop UI to redraw if it happens to be open!
	if SignalBus.has_signal("market_updated"):
		SignalBus.market_updated.emit()

# ==============================================================================
# INTERNAL LOGIC & SAVING
# ==============================================================================
func _scan_for_agents() -> void:
	_load_dir_recursive(AGENT_DIRECTORY)
	print("🤝 MarketManager: Loaded %d free agents into the market." % available_agents.size())

func _load_dir_recursive(path: String) -> void:
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				if file_name != "." and file_name != "..":
					_load_dir_recursive(path + "/" + file_name)
			else:
				if file_name.ends_with(".tres") or file_name.ends_with(".res"):
					var resource = load(path + "/" + file_name)
					if resource is ESportPlayer: 
						available_agents.append(resource)
			file_name = dir.get_next()

func get_save_data() -> Array:
	var saved_agents = []
	for agent in available_agents:
		if agent.resource_path != "":
			# 1. It's a pre-made .tres file, just save the path!
			saved_agents.append({"type": "path", "data": agent.resource_path})
		else:
			# 2. It's a dynamically generated rookie! Save their actual stats.
			saved_agents.append({
				"type": "dynamic",
				"alias": agent.alias,
				"age": agent.age,
				"preferred_role": agent.preferred_role,
				"aim": agent.aim,
				"game_sense": agent.game_sense,
				"teamwork": agent.teamwork,
				"hiring_cost": agent.hiring_cost,
				"current_energy": agent.current_energy,
				"current_focus": agent.current_focus
			})
	return saved_agents

func load_save_data(data: Array) -> void:
	available_agents.clear()
	for item in data:
		# Safety check: If it's an old save file that just had raw strings, handle it gracefully
		if typeof(item) == TYPE_STRING:
			if item != "":
				var agent = load(item)
				if agent is ESportPlayer: available_agents.append(agent)
			continue
			
		# Handle our new dictionary format
		if typeof(item) == TYPE_DICTIONARY:
			if item.get("type") == "path":
				var agent = load(item["data"])
				if agent is ESportPlayer: 
					available_agents.append(agent)
					
			elif item.get("type") == "dynamic":
				# Rebuild the rookie from scratch!
				var rookie = ESportPlayer.new()
				rookie.alias = item.get("alias", "Unknown")
				rookie.age = item.get("age", 18)
				rookie.preferred_role = item.get("preferred_role", 0)
				rookie.aim = item.get("aim", 50)
				rookie.game_sense = item.get("game_sense", 50)
				rookie.teamwork = item.get("teamwork", 50)
				rookie.hiring_cost = item.get("hiring_cost", 1000)
				rookie.current_energy = item.get("current_energy", 100)
				rookie.current_focus = item.get("current_focus", 100)
				
				available_agents.append(rookie)
