class_name ActionCalculator
extends RefCounted

# ==============================================================================
# CALCULATE TIME COST (In-Game Minutes)
# ==============================================================================
static func get_effective_time_cost(action: ActionData, player: ESportPlayer = null) -> float:
	var base_time = float(action.time_cost_minutes)
	var time_efficiency_mod: float = 0.0 
	
	# If a player is assigned, check their specific upgrades!
	if player != null:
		# TODO: Ask your Item/Progression manager for this player's specific efficiency stats
		# Example: time_efficiency_mod = player.get_stat("action_time_efficiency")
		pass
		
	# Logic: 0.1 efficiency means 10% faster (90% of the time cost)
	var final_time_mult = max(0.1, 1.0 - time_efficiency_mod)
	return base_time * final_time_mult

# ==============================================================================
# CALCULATE ENERGY COST MULTIPLIER
# ==============================================================================
static func get_energy_cost_multiplier(_action: ActionData, player: ESportPlayer = null) -> float:
	var energy_efficiency_percent: float = 0.0 
	
	if player != null:
		# Example: energy_efficiency_percent = player.get_stat("energy_efficiency")
		pass
		
	# Logic: 0.2 means 20% off, so multiplier is 0.8
	return max(0.1, 1.0 - energy_efficiency_percent)

# ==============================================================================
# CALCULATE COOLDOWN (Real-World Seconds)
# ==============================================================================
static func get_effective_cooldown(action: ActionData, player: ESportPlayer = null) -> float:
	var cooldown_reduction_flat: float = 0.0
	var cooldown_reduction_percent: float = 0.0
	
	if player != null:
		# Example: cooldown_reduction_flat = player.get_stat("cooldown_reduction_flat")
		pass
		
	var cd_after_flat = max(0.1, action.base_duration - cooldown_reduction_flat)
	return max(0.1, cd_after_flat * (1.0 - cooldown_reduction_percent))
