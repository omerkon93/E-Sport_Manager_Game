extends Resource
class_name QuestData

@export var id: String = "quest_01"
@export var title: String = "Rookie Scout"
@export_multiline var description: String = "Sign your first free agent to the bench."

@export_group("Unlock Conditions")
@export var required_story_flags: Array[StoryFlag] = []
@export var prerequisite_quests: Array[QuestData] = []

@export_group("Objectives")
## What flags do the player need to unlock? (All must be true)
@export var target_story_flags: Array[StoryFlag] = []
@export var target_actions: Dictionary[ActionData, int] = {}

@export_group("Reset Mechanics")
## If true, all progress on target actions resets to 0 when a new day starts.
@export var reset_on_new_day: bool = false

@export_group("Rewards")
@export var reward_currencies: Dictionary[CurrencyDefinition, float] = {}
@export var reward_story_flags: Array[StoryFlag] = []

func get_objective_text(current_progress: Dictionary = {}) -> String:
	var lines: Array[String] = []
	
	# No more type checking needed! 'action' is guaranteed to be ActionData
	for action in target_actions:
		var required = target_actions[action]
		var current = current_progress.get(action.id, 0)
		lines.append("%s: %d / %d" % [action.display_name, current, required])
			
	return "\n".join(lines)
