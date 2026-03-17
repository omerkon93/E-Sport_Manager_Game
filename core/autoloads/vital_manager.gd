extends Node

# We keep definitions here so the UI can still look up icons and colors globally!
var _definitions: Dictionary = {}

func initialize_vitals(vitals: Array[VitalDefinition]) -> void:
	for v in vitals:
		_definitions[v.type] = v

func get_definition(type: VitalDefinition.VitalType) -> VitalDefinition:
	return _definitions.get(type, null)

# ==============================================================================
# TEAM ACTIONS (The New Manager Hooks)
# ==============================================================================

## Exhausts the active roster after they play a match
func process_match_exhaustion(team: ESportTeam, energy_cost: float = -25.0) -> void:
	for player in team.active_roster:
		if player != null:
			player.change_vital(VitalDefinition.VitalType.ENERGY, energy_cost)
			# They lose some focus/morale too!
			player.change_vital(VitalDefinition.VitalType.FOCUS, -10.0) 

## Recovers the team's vitals when advancing the week
func process_weekly_recovery(team: ESportTeam) -> void:
	for player in team.active_roster:
		if player != null:
			player.change_vital(VitalDefinition.VitalType.ENERGY, 100.0) # Full rest
			player.change_vital(VitalDefinition.VitalType.FOCUS, 20.0)   # Recover morale
