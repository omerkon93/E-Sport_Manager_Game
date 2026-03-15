extends Node

# Global signal to request a popup
# position: Screen coordinates (Vector2)
# text: The string to display (e.g., "+10")
# color: The text color
@warning_ignore("unused_signal")
signal request_floating_text(position: Vector2, text: String, color: Color)

@warning_ignore("unused_signal")
signal message_logged(text: String, color: Color)

@warning_ignore("unused_signal")
signal dialogue_action(action_id: String)

@warning_ignore("unused_signal")
signal show_info_requested(title: String, description: String)

@warning_ignore("unused_signal")
signal study_dialog_requested(action_button: Node, action_data: ActionData)

@warning_ignore("unused_signal")
signal open_settings_requested
