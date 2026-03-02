extends Resource
class_name QuestData

@export var id: String = "quest_01"
@export var title: String = "Helpdesk Hero"
@export_multiline var description: String = "Clear out the morning queue. Resolve 10 basic IT tickets."

@export_category("Unlock Conditions")
## Quest only appears if this story flag is true
@export var required_story_flag: StoryFlag
## Quest only appears if another quest is finished
@export var prerequisite_quest: QuestData

@export_category("Objectives")
## What flag does the player needs to unlock?
@export var target_story_flag: StoryFlag
## What action does the player need to click? (e.g., "work_001_helpdesk")
@export var target_action: ActionData
## How many times do they need to do it?
@export var required_amount: int = 10

@export_category("Rewards")
## Optional: The currency to reward (using your existing definitions)
@export var reward_currency: CurrencyDefinition
@export var reward_amount: float = 100.0
## Optional: The StoryFlag to reward (using your existing definitions)
@export var reward_story_flag: StoryFlag
