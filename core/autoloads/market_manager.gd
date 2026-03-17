extends Node

const AGENT_DIRECTORY = "res://game_data/entities/players/free_agents/"


# This is the "Shop Inventory"
var available_agents: Array[ESportPlayer] = []

func _ready() -> void:
	_scan_for_agents()

# ==============================================================================
# PUBLIC API
# ==============================================================================
func try_hire_agent(agent: ESportPlayer, team: ESportTeam, money_type: int) -> bool:
	# 1. Validation
	if agent == null or team == null: return false
	if not available_agents.has(agent): return false # Make sure they are actually in the shop!

	# 2. Check Requirements
	if not CurrencyManager.has_enough_currency(money_type, agent.hiring_cost):
		print("Not enough money to hire ", agent.alias)
		return false

	# 3. Consume Costs
	CurrencyManager.spend_currency(money_type, agent.hiring_cost)

	# 4. Handle Acquisition
	available_agents.erase(agent) # Remove from shop
	team.bench.append(agent)      # Add to team bench
	
	# 5. Handle Salary (Using your existing Subscription logic!)
	if agent.salary_subscription:
		SubscriptionManager.subscribe(agent.salary_subscription)
		print("Started paying salary for ", agent.alias)

	print("🤝 Successfully hired ", agent.alias, " to the bench!")
	return true

# ==============================================================================
# PRIVATE HELPERS (Stolen directly from your ItemManager!)
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
					# Only grab it if it's an ESportPlayer!
					if resource is ESportPlayer: 
						available_agents.append(resource)
			file_name = dir.get_next()

# --- SAVE / LOAD LOGIC ---
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
