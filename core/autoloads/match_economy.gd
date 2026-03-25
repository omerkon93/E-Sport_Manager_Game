extends Node
class_name MatchEconomy

const MAX_MONEY = 16000
const STARTING_MONEY = 800
const KILL_REWARD = 300
const WIN_REWARD = 3250
const LOSS_REWARD = 1900 

# Key: ESportPlayer -> Value: int (Current Bank Balance)
var bank_accounts: Dictionary = {}

func initialize_economy(team_a: ESportTeam, team_b: ESportTeam) -> void:
	bank_accounts.clear()
	for player in team_a.active_roster:
		if player != null: bank_accounts[player] = STARTING_MONEY
	for player in team_b.active_roster:
		if player != null: bank_accounts[player] = STARTING_MONEY
		
	print("💰 MatchEconomy: Bank accounts initialized at $800.")

func award_kill_bonus(killer_data: ESportPlayer) -> void:
	if killer_data and bank_accounts.has(killer_data):
		bank_accounts[killer_data] += KILL_REWARD
		bank_accounts[killer_data] = min(bank_accounts[killer_data], MAX_MONEY)

func award_round_end(team_a_roster: Array, team_b_roster: Array, team_a_won: bool) -> void:
	# Payout Team A
	for player in team_a_roster:
		if player != null and bank_accounts.has(player):
			var payout = WIN_REWARD if team_a_won else LOSS_REWARD
			bank_accounts[player] += payout
			bank_accounts[player] = min(bank_accounts[player], MAX_MONEY)
			
	# Payout Team B
	for player in team_b_roster:
		if player != null and bank_accounts.has(player):
			var payout = LOSS_REWARD if team_a_won else WIN_REWARD
			bank_accounts[player] += payout
			bank_accounts[player] = min(bank_accounts[player], MAX_MONEY)
			
	print("💸 MatchEconomy: Round payouts distributed!")
	
# --- Helper for the Armory ---
func get_balance(player: ESportPlayer) -> int:
	return bank_accounts.get(player, 0)
	
func spend_money(player: ESportPlayer, amount: int) -> void:
	if player and bank_accounts.has(player):
		bank_accounts[player] -= amount
