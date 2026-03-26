extends HBoxContainer
class_name PlayerStatsDisplay

@onready var name_label: Label = %NameLabel
@onready var role_label: Label = %RoleLabel
@onready var aim_label: Label = %AimLabel
@onready var sense_label: Label = %SenseLabel
@onready var teamwork_label: Label = %TeamworkLabel

const ROLE_NAMES = {
	ESportPlayer.PlayerRole.ENTRY_FRAGGER: "ENTRY",
	ESportPlayer.PlayerRole.AWPER: "AWPER",
	ESportPlayer.PlayerRole.IGL: "IGL",
	ESportPlayer.PlayerRole.SUPPORT: "SUPPORT",
	ESportPlayer.PlayerRole.LURKER: "LURKER"
}

## Call this from ANY UI panel to instantly populate the labels!
func setup_display(player: ESportPlayer) -> void:
	if player == null:
		name_label.text = "Empty Slot"
		role_label.text = ""
		aim_label.text = ""
		sense_label.text = ""
		teamwork_label.text = ""
		return
		
	name_label.text = player.alias
	role_label.text = ROLE_NAMES.get(player.preferred_role, "UNKNOWN")
	aim_label.text = str(player.aim)
	sense_label.text = str(player.game_sense)
	teamwork_label.text = str(player.teamwork)
