class_name CurrencyDefinition extends Resource

enum CurrencyType {
	NONE = 0,
	MONEY = 1,
	SPIRIT = 2
}

@export var type: CurrencyType = CurrencyType.NONE
@export var display_name: String = "Currency Name"
@export var icon: Texture2D
@export var text_icon: String = "$" # Use Ψ for Spirit!
@export var display_color: Color = Color.WHITE
@export var initial_amount: float = 0.0
@export var max_amount: float = 999999.0
@export var prefix: String = ""
@export var description: String = ""

# --- FORMATTING HELPERS ---

## Used for the Shop (e.g., "[color=#FFD700]$1.5k[/color]")
func format_cost(amount: float) -> String:
	var hex = display_color.to_html(false)
	return "[color=#%s]%s %s[/color]" % [hex, NumberFormatter.format_value(amount), text_icon]

## Used for Action Button Costs (e.g., "[color=#FFD700]-$1.5k[/color]")
func format_loss(amount: float) -> String:
	var hex = display_color.to_html(false)
	return "[color=#%s]-%s %s[/color]" % [hex, NumberFormatter.format_value(amount), text_icon]

## Used for Rewards (e.g., "[color=#FFD700]+$1.5k[/color]")
func format_gain(amount: float) -> String:
	var hex = display_color.to_html(false)
	return "[color=#%s]+%s %s[/color]" % [hex, NumberFormatter.format_value(amount), text_icon]
