extends Resource
class_name SubscriptionItem

# --- IDENTITY ---
@export_category("Identity")
@export var id: String = "sub_rent"
@export var display_name: String = "Weekly Rent"
@export_multiline var description: String = "Living expenses."

# --- COSTS ---
@export_category("Cost")
@export var cost_amount: float = 100.0
@export var currency_type: CurrencyDefinition.CurrencyType = CurrencyDefinition.CurrencyType.MONEY

# --- TIMING ---
@export_category("Timing")
## How many days between payments? (e.g. 7 for weekly)
@export var interval_days: int = 7

## If true, automatically tries to pay and renews.
## If false, it cancels itself after one payment (like a loan installment).
@export var auto_renew: bool = true

# --- PENALTY ---
@export_category("Failure")
## Story flag to trigger if payment fails (e.g. "game_over_eviction")
@export var penalty_flag: StoryFlag
