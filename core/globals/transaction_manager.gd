class_name TransactionManager
extends RefCounted

# ==============================================================================
# 1. ACTION EXECUTION (Player & Global)
# ==============================================================================
static func try_perform_action(action: ActionData, target_player: ESportPlayer = null) -> bool:
	# Ask the calculator for the exact cost based on who is doing it!
	var cost_multiplier = ActionCalculator.get_energy_cost_multiplier(action, target_player)
	
	# --- PHASE 1: VALIDATION (Can we afford this?) ---
	
	# A. Player Vitals Check
	if not action.vital_costs.is_empty():
		if target_player == null:
			push_error("TransactionManager: Action costs vitals, but no target_player was provided!")
			return false
			
		for vit_type in action.vital_costs:
			var final_cost = action.vital_costs[vit_type] * cost_multiplier
			# Assumes ESportPlayer has a has_enough_vital() helper!
			if not target_player.has_enough_vital(vit_type, final_cost):
				return false
				
	# B. Global Currency Check
	for cur_type in action.currency_costs:
		var amount = action.currency_costs[cur_type]
		if not CurrencyManager.has_enough_currency(cur_type, amount):
			return false

	# --- PHASE 2: CONSUME COSTS ---
	
	# A. Drain Player Vitals
	if target_player != null:
		for vit_type in action.vital_costs:
			var final_cost = action.vital_costs[vit_type] * cost_multiplier
			target_player.change_vital(vit_type, -final_cost) # Note the negative sign to subtract!
			
	# B. Spend Global Currency
	for cur_type in action.currency_costs:
		var amount = action.currency_costs[cur_type]
		CurrencyManager.spend_currency(cur_type, amount)

	# --- PHASE 3: APPLY REWARDS ---
	
	# A. Restore Player Vitals
	if target_player != null:
		for vit_type in action.vital_gains:
			target_player.change_vital(vit_type, action.vital_gains[vit_type])
			
	# B. Add Global Currency
	for cur_type in action.currency_gains:
		var amount = action.currency_gains[cur_type]
		CurrencyManager.add_currency(cur_type, amount)
		
	# --- PHASE 4: TIME & SIGNALS ---
	
	if "effective_time_cost" in action and action.effective_time_cost > 0:
		if TimeManager and TimeManager.has_method("advance_time"):
			TimeManager.advance_time(action.effective_time_cost)

	# Optional: Broadcast to the SignalBus so QuestManager can hear it!
	if SignalBus.has_signal("action_performed"):
		SignalBus.action_performed.emit(action)

	return true


# ==============================================================================
# 2. MARKET EXECUTION (Hiring)
# ==============================================================================
static func try_hire_agent(agent: ESportPlayer, team: ESportTeam, money_type: int) -> bool:
	# 1. Validation
	if agent == null or team == null: 
		return false
	if not MarketManager.is_agent_available(agent): 
		return false 

	# 2. Check Affordability
	if not CurrencyManager.has_enough_currency(money_type, agent.hiring_cost):
		print("TransactionManager: Not enough money to hire ", agent.alias)
		return false

	# 3. Process Transaction
	CurrencyManager.spend_currency(money_type, agent.hiring_cost)
	MarketManager.remove_agent(agent) 
	
	# 4. Handle Acquisition (CRITICAL: Duplicate the Resource!)
	var hired_agent = agent.duplicate(true) 
	
	hired_agent.set_meta("original_path", agent.resource_path)
	
	team.bench.append(hired_agent)  
	
	# 5. Handle Subscriptions
	if hired_agent.salary_subscription:
		SubscriptionManager.subscribe(hired_agent.salary_subscription)
		print("TransactionManager: Started paying salary for ", hired_agent.alias)

	print("🤝 Successfully hired ", hired_agent.alias, " to the bench!")
	return true


# ==============================================================================
# 3. REWARD EXECUTION (Quests)
# ==============================================================================
static func process_quest_rewards(quest: QuestData) -> void:
	# 1. Payout Currencies
	for currency in quest.reward_currencies:
		var amt = quest.reward_currencies[currency]
		if amt > 0:
			CurrencyManager.add_currency(currency.type, amt)
			
	# 2. Apply Story Flags
	for flag in quest.reward_story_flags:
		if flag:
			ProgressionManager.set_flag(flag, true)


# ==============================================================================
# 4. SUBSCRIPTION EXECUTION (Bills)
# ==============================================================================
static func process_subscription(item: SubscriptionItem) -> bool:
	# 1. Validate Funds
	if CurrencyManager.has_enough_currency(item.currency_type, item.cost_amount):
		# 2. Pay the Bill
		CurrencyManager.spend_currency(item.currency_type, item.cost_amount)
		SignalBus.message_logged.emit("Paid %s (-$%d)" % [item.display_name, item.cost_amount], Color.ORANGE)
		return true
		
	else:
		# 3. Handle Bankruptcy / Penalties
		SignalBus.message_logged.emit("MISSED PAYMENT: %s!" % item.display_name, Color.RED)
		
		if item.penalty_flag != null:
			print("💀 Triggering Penalty Flag: ", item.penalty_flag)
			ProgressionManager.set_flag(item.penalty_flag, true)
			
		return false
