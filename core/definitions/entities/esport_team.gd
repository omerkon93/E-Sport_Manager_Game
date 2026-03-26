class_name ESportTeam
extends Resource

signal roster_changed # NEW: The UI will listen to this!

## 🛡️ Team Identity
@export_group("Team Identity")
@export var team_name: String = "New Team"
@export var team_logo: Texture2D 
@export var is_player_owned: bool = false 

## 👥 Roster
@export_group("Roster")
@export var active_roster: Array[ESportPlayer] = [null, null, null, null, null]
@export var bench: Array[ESportPlayer] = []

## 💰 Club Finances
@export_group("Club Finances")
@export var budget: int = 250000 # The meta-currency for buying players

## 📊 Match-Day Helper Functions
func get_team_aim() -> int:
	var total_aim: int = 0
	for player in active_roster:
		if player != null: 
			total_aim += player.aim
	return total_aim

func get_team_game_sense() -> int:
	var total_sense: int = 0
	for player in active_roster:
		if player != null:
			total_sense += player.game_sense
	return total_sense

func get_team_teamwork() -> int:
	var total_teamwork: int = 0
	for player in active_roster:
		if player != null:
			total_teamwork += player.teamwork
	return total_teamwork

func get_overall_power() -> int:
	return get_team_aim() + get_team_game_sense() + get_team_teamwork()

# --- ROSTER MANAGEMENT ---

func bench_player(player: ESportPlayer) -> void:
	var idx = active_roster.find(player)
	if idx != -1:
		active_roster[idx] = null 
		bench.append(player)
		# USE THE BUS:
		SignalBus.team_roster_changed.emit(self)

func sub_in_player(player: ESportPlayer) -> bool:
	var empty_idx = active_roster.find(null)
	
	if empty_idx != -1:
		bench.erase(player)
		active_roster[empty_idx] = player
		print(player.alias + " was subbed into the active roster!")
		roster_changed.emit() # Tell the UI to redraw!
		return true
	else:
		print("Cannot sub in: Active roster is full! Bench someone first.")
		return false

func is_match_ready() -> bool:
	if active_roster.size() != 5: return false
	if active_roster.has(null): return false
	return true

# --- ORGANIZATION MANAGEMENT ---

func hire_player(player: ESportPlayer) -> void:
	if not bench.has(player) and not active_roster.has(player):
		bench.append(player)
		# USE THE BUS:
		SignalBus.team_roster_changed.emit(self) 
		SignalBus.message_logged.emit("🤝 " + team_name + " hired " + player.alias + "!", Color.GREEN)

func release_player(player: ESportPlayer) -> void:
	# 1. Remove from active roster
	var active_idx = active_roster.find(player)
	if active_idx != -1:
		active_roster[active_idx] = null
		
	# 2. Remove from bench
	if bench.has(player):
		bench.erase(player)
		
	print("👋 " + team_name + " fired " + player.alias + "!")
	
	# 3. Tell the game!
	SignalBus.team_roster_changed.emit(self)
	SignalBus.message_logged.emit("🔥 Fired " + player.alias + " to save budget.", Color.RED)

func can_afford(amount: int) -> bool:
	return budget >= amount

func spend_budget(amount: int) -> void:
	budget -= amount
	print("💸 Spent $" + str(amount) + ". Remaining budget: $" + str(budget))
