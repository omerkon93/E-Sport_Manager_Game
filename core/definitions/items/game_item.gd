extends Resource
class_name GameItem

# --- ENUMS ---
enum ItemType {
	## Immediate use items (e.g., Coffee, Scripts). Grants temporary ActionData rewards.
	CONSUMABLE,
	## Instant purchase, 1-time unlocks (e.g., Certifications, Manuals). 
	## Unlocks the path to research new Skills.
	KNOWLEDGE,
	## Takes time to research/practice (e.g., AD Management, Cable Routing). 
	## Grants permanent stat boosts or workflow efficiencies.
	SKILL,
	## Crafting components (e.g., RAM, Cables, Switches).
	HARDWARE
}

# --- IDENTITY ---
@export_category("Identity")

## The unique string identifier used for saving, loading, and database lookups.
@export var id: String = "item_id"

## The name of the item as it appears to the player in the UI.
@export var display_name: String = "Item Name"

## Flavour text or mechanical details shown in the item's tooltip.
@export_multiline var description: String = ""

## The visual representation of the item in the shop or inventory.
@export var icon: Texture2D

## Defines how the game handles this item (e.g., one-time use vs. permanent upgrade).
@export var item_type: ItemType = ItemType.CONSUMABLE

## The specific action this upgrade enhances.
@export var target_action: ActionData

## This is directed at the Knowledge GameItem of a SKILL GameItem.
@export var parent_knowledge_item: GameItem

# --- COMPONENTS ---
@export_category("Logic")
@export_group("Requirements")
## Amount of currency required for the item
@export var currency_cost: Dictionary[CurrencyDefinition, int] = {}

## Amount of vitals required for the item
@export var vital_cost: Dictionary[VitalDefinition, int] = {}

## The Story Flag REQUIRED for this item to even appear/be clickable in the shop.
@export var story_flags_requirement: Array[StoryFlag] = []

@export_group("Rewards")
## The permanent stat boosts or modifiers granted when this item is acquired.
@export var effects: Array[Resource] = []

## An ActionData event triggered immediately upon purchase (great for Consumable vitals/currency).
@export var on_purchase_action: ActionData

## A specific Story Flag to unlock upon acquiring this item (useful for progression gates).
@export var story_flags_reward: Array[StoryFlag] = []

# --- RESEARCH SETTINGS ---
@export_group("Research Duration")
## Time in MINUTES required to unlock this skill. Only used if ItemType is SKILL.
@export var research_duration_minutes: int = 60

# --- SPECIAL LOGIC ---
@export_group("Special")
## A recurring bill or subscription that begins automatically when this item is purchased.
@export var subscription_to_start: SubscriptionItem


# --- AUDIO ---
@export_group("Presentation")

## The sound effect that plays when the player successfully buys or finishes researching this item.
@export var audio_on_purchase: AudioStream
