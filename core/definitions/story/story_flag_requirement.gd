extends Resource
class_name StoryFlagRequirement

## The flag required to unlock this item.
@export var required_flag: StoryFlag

## Should the flag be TRUE or FALSE to pass?
@export var required_value: bool = true
