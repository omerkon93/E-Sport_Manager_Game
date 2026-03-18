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
	var paths = []
	for agent in available_agents:
		paths.append(agent.resource_path)
	return paths

func load_save_data(data: Array) -> void:
	available_agents.clear()
	for path in data:
		var agent = load(path)
		if agent is ESportPlayer:
			available_agents.append(agent)
