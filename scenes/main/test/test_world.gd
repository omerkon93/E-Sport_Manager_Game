extends Node2D

# Update the reference path to your new CombinedMenu
@onready var combined_menu: CombinedMenu = %CombinedMenu

func _ready() -> void:
	# Optional: Set the starting tab index
	# 0 = Actions, 1 = Shop (Depends on your Scene Tree order)
	if combined_menu.tab_container:
		combined_menu.tab_container.current_tab = 0
