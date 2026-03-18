extends Node

# ==============================================================================
# UI & VISUAL FEEDBACK
# ==============================================================================
## Emitted to spawn floating text (e.g., "+10 Energy" over a player)
@warning_ignore("unused_signal")
signal request_floating_text(position: Vector2, text: String, color: Color)

## Emitted to send a string to the on-screen console or notification log
@warning_ignore("unused_signal")
signal message_logged(text: String, color: Color)

## Emitted to open generic info popups (e.g., hovering over a stat)
@warning_ignore("unused_signal")
signal show_info_requested(title: String, description: String)

## Emitted to open the specific study/action confirmation dialog
@warning_ignore("unused_signal")
signal study_dialog_requested(action_button: Node, action_data: ActionData)

## Emitted by UI buttons to open the global settings menu
@warning_ignore("unused_signal")
signal open_settings_requested


# ==============================================================================
# DIALOGUE SYSTEM
# ==============================================================================
## Emitted by game events/NPCs. Listener: DialogueUI (Wakes up and shows the text)
@warning_ignore("unused_signal")
signal dialogue_requested(sequence: DialogueSequence)

## Emitted by DialogueUI when a specific narrative button is clicked
@warning_ignore("unused_signal")
signal dialogue_action(action_id: String)


# ==============================================================================
# MATCH SIMULATION
# ==============================================================================
## Emitted by the UI. Listener: MatchSimulator (Starts the async loop)
@warning_ignore("unused_signal")
signal start_match_requested(team_a: ESportTeam, team_b: ESportTeam)

## Emitted by the UI. Listener: MatchSimulator (Forces the loop to skip await timers)
@warning_ignore("unused_signal")
signal skip_match_requested


# ==============================================================================
# GLOBAL GAME STATE (Economy, Time, & Saving)
# ==============================================================================
## Emitted by CurrencyManager when money changes. Listener: TopBar UI, ProgressionManager
@warning_ignore("unused_signal")
signal game_currency_changed(type: int, amount: float)

## Emitted by ESportPlayer/VitalManager when stats change. Listener: Player UI, ProgressionManager
@warning_ignore("unused_signal")
signal game_vital_changed(type: int, current: float, max_val: float)

## Emitted by TimeManager every minute. Listener: Clock UI
@warning_ignore("unused_signal")
signal game_time_updated(day: int, hour: int, minute: int)

## Emitted by TimeManager at midnight. Listener: SubscriptionManager, QuestManager
@warning_ignore("unused_signal")
signal game_time_day_started(day: int)

## Emitted by SaveManager when a file finishes loading. Listener: All UI (Triggers a visual refresh)
@warning_ignore("unused_signal")
signal game_loaded


# ==============================================================================
# PROGRESSION & QUESTS
# ==============================================================================
## Emitted by TransactionManager when an action is successfully bought/completed.
@warning_ignore("unused_signal")
signal action_performed(action: ActionData)

## Emitted by ProgressionManager when a narrative/unlock flag turns true.
@warning_ignore("unused_signal")
signal story_flag_changed(flag_id: String, value: bool)
