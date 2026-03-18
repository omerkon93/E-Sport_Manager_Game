extends Resource
class_name DialogueOption

@export_category("Option Details")
## The text displayed on the button for this dialogue choice (e.g., "Reset Password" or "Escalate Ticket").
@export var text: String = "Option Text"

## What happens when this option is clicked. 
## - Drag ActionData to give a reward/penalty and close.
## - Drag DialogueSlide/Sequence to continue the conversation.
## - Drag DialogueTrigger to fire a signal.
## - Leave <empty> to simply close the ticket.
@export var target: Resource 

@export_category("Unlock Conditions")
## Optional: The GameItem upgrade required for this option to be visible (e.g., Active Directory Basics). Leave empty if it is always available.
#@export var required_upgrade: GameItem 

## Optional: A specific StoryFlag required for this option to be visible. Leave empty if no story event is needed.
@export var required_story_flag: StoryFlag
