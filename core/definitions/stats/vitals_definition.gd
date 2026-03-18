extends Resource
class_name VitalDefinition

enum VitalType {
	NONE = 100,
	ENERGY,
	FULLNESS,
	FOCUS,
	SANITY
}

@export var type: VitalType = VitalType.NONE
@export var display_name: String
@export var icon: Texture2D
@export var text_icon: String = "⚡"
@export var display_color: Color = Color.WHITE
@export var description: String = ""

# Stats specific to Vitals
@export var default_max_value: float = 100.0
@export var gradient: Gradient

# --- FORMATTING HELPERS ---

## Used for the Shop (e.g., "[color=#FFA500]10 ⚡[/color]")
func format_cost(amount: float) -> String:
	var hex = display_color.to_html(false)
	return "[color=#%s]%s %s[/color]" % [hex, NumberFormatter.format_value(amount), text_icon]

## Used for Action Button Costs (e.g., "[color=#FFA500]-10 ⚡[/color]")
func format_loss(amount: float) -> String:
	var hex = display_color.to_html(false)
	return "[color=#%s]-%s %s[/color]" % [hex, NumberFormatter.format_value(amount), text_icon]

## Used for Rewards (e.g., "[color=#FFA500]+10 ⚡[/color]")
func format_gain(amount: float) -> String:
	var hex = display_color.to_html(false)
	return "[color=#%s]+%s %s[/color]" % [hex, NumberFormatter.format_value(amount), text_icon]
