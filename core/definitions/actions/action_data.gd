extends Resource
class_name ActionData

enum ActionCategory { CAREER, SURVIVAL, SPIRITUAL, OTHER }

# --- IDENTITY ---
@export_category("Identity")
@export var id: String = "action_id"
@export var display_name: String = "New Action"
@export var icon: Texture2D
@export_multiline var description: String = ""
@export var category: ActionCategory = ActionCategory.CAREER

# --- SETTINGS ---
@export_category("Settings")
@export_group("Unlock Settings")
@export var is_unlocked_by_default: bool = true 
@export var is_visible_in_menu: bool = true

@export_group("Time & Pacing")
@export var use_cooldown: bool = true 
@export var is_study_action: bool = false
## Action cooldown, counted in real-world seconds
@export var base_duration: float = 0.01
## Action time cost, counted in in-game minutes
@export var time_cost_minutes: int = 60

# --- ECONOMY ---
@export_category("Economy")                  
@export_group("Costs")
@export var vital_costs: Dictionary[VitalDefinition.VitalType, float] = {}
@export var currency_costs: Dictionary[CurrencyDefinition.CurrencyType, float] = {}

@export_group("Rewards")
@export var vital_gains: Dictionary[VitalDefinition.VitalType, float] = {}
@export var currency_gains: Dictionary[CurrencyDefinition.CurrencyType, float] = {}

@export_category("Requirements & Events")    
@export var required_story_flag: StoryFlag
## The player MUST complete all of these quests before the action unlocks
@export var required_completed_quests: Array[QuestData] = []
@export var trigger_signal_id: String = ""

# --- MESSAGES ---
@export_category("Messages")
@export var failure_messages: Dictionary = {}
