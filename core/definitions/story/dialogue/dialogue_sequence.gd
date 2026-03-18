extends Resource
class_name DialogueSequence

@export var slides: Array[DialogueSlide] = []

@export_category("Random Event Settings")
## Which action button should this ticket appear in? (e.g., Helpdesk Action)
@export var parent_action: ActionData

## Optional: Only add this ticket to the random pool if they have this upgrade
#@export var required_pool_upgrade: GameItem

## Optional: Only add this ticket if a specific story flag is met
@export var required_story_flag: StoryFlag
