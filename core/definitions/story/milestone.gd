extends Resource
class_name Milestone

@export_group("Reward")
## The flag to set to TRUE when this milestone is met.
@export var target_flag: StoryFlag 

## Text shown in the UI popup.
@export var notification_text: String = "Milestone Reached!"

# --- REQUIREMENTS (All filled fields must be met) ---

@export_group("Currency Requirements")
@export var required_currency: CurrencyDefinition.CurrencyType = CurrencyDefinition.CurrencyType.MONEY
@export var currency_amount: float = 0.0

## If true, requirement is met when currency is LESS than amount.
## [br]Useful for "Bankruptcy" or "Spend it all" milestones.
@export var currency_is_less_than: bool = false

@export_group("Vital Requirements")
@export var required_vital: VitalDefinition.VitalType = VitalDefinition.VitalType.NONE
@export var vital_amount: float = 0.0

## If true, requirement is met when vital is LESS than amount.
## [br]Useful for "Low Health" or "Starvation" events.
@export var vital_is_less_than: bool = false

@export_group("Time Requirements")
## The day. Set to -1 to ignore.
@export var min_day: int = -1
## The hour (0-23).
@export var min_hour: int = 0

## If true, requirement is met BEFORE this time (Deadline).
## [br]If false, requirement is met AFTER this time (Wait).
@export var time_is_deadline: bool = false

@export_group("Research Requirements")
## Triggers the moment this specific item starts being researched.
#@export var required_started_research: GameItem

## Triggers the moment ANY research begins.
@export var any_research_started: bool = false

## Triggers the moment this specific item FINISHES being researched.
#@export var required_finished_research: GameItem

## Triggers the moment ANY research FINISHES.
@export var any_research_finished: bool = false
