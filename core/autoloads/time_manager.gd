extends Node

# --- SIGNALS (Restored!) ---
signal time_updated(day: int, hour: int, minute: int)
signal day_started(day: int)
signal night_started(day: int)
signal time_advanced(minutes: int) 

# --- CONSTANTS ---
const MINUTES_PER_HOUR = 60
const HOURS_PER_DAY = 24
const NIGHT_START_HOUR = 20
const DAY_START_HOUR = 6

# --- STATE ---
var current_day: int = 1
var current_hour: int = 8
var current_minute: int = 0

func _ready() -> void:
	# Register for the automatic SaveManager!
	add_to_group("persist")

# ==============================================================================
# TIME LOGIC
# ==============================================================================
func advance_time(minutes_to_add: int) -> void:
	current_minute += minutes_to_add
	
	# Emit the local delta
	time_advanced.emit(minutes_to_add)
	
	# Handle Hour Rollover
	while current_minute >= MINUTES_PER_HOUR:
		current_minute -= MINUTES_PER_HOUR
		current_hour += 1
		
		# Handle Day Rollover
		if current_hour >= HOURS_PER_DAY:
			current_hour -= HOURS_PER_DAY
			current_day += 1
			
			# Emit local day start
			day_started.emit(current_day)
			
			# Emit to the GLOBAL SignalBus so subs and progression hear it!
			if SignalBus.has_signal("game_time_day_started"):
				SignalBus.game_time_day_started.emit(current_day)
				
			print("New Day Started: Day ", current_day)

	if current_hour == NIGHT_START_HOUR and current_minute == 0:
		night_started.emit(current_day)
		
	# Emit local time update
	time_updated.emit(current_day, current_hour, current_minute)
	
	# Emit global time update
	if SignalBus.has_signal("game_time_updated"):
		SignalBus.game_time_updated.emit(current_day, current_hour, current_minute)

# ==============================================================================
# UI HELPERS
# ==============================================================================
func get_time_string() -> String:
	# Read the global setting to decide how to format the text!
	var use_24h = SettingsManager.get_setting("time_format_24h", true)
	
	if use_24h:
		return "%02d:%02d" % [current_hour, current_minute]
	else:
		var period = "AM"
		var display_hour = current_hour
		if current_hour >= 12:
			period = "PM"
			if current_hour > 12: display_hour -= 12
		if display_hour == 0: display_hour = 12
		return "%02d:%02d %s" % [display_hour, current_minute, period]

# Converts raw minutes into a clean "Hours" display string.
func format_duration_in_hours(total_minutes: int) -> String:
	var hours = float(total_minutes) / 60.0
	
	# If it's a perfectly whole number of hours (e.g., 60 mins = 1.0 hr)
	if fmod(hours, 1.0) == 0.0:
		return "%d hr" % int(hours)
	else:
		# If there are leftover minutes, show 1 decimal place (e.g., 90 mins = 1.5 hr)
		return "%.1f hr" % hours

# ==============================================================================
# PERSISTENCE & RESET
# ==============================================================================
func get_save_data() -> Dictionary:
	return {
		"day": current_day,
		"hour": current_hour,
		"minute": current_minute
	}

func load_save_data(data: Dictionary) -> void:
	current_day = data.get("day", 1)
	current_hour = data.get("hour", 8)
	current_minute = data.get("minute", 0)
	
	# Force the UI clock to update instantly on load
	time_updated.emit(current_day, current_hour, current_minute)

func reset() -> void:
	current_day = 1
	current_hour = DAY_START_HOUR # Assuming 6 AM based on your constants!
	current_minute = 0
	
	time_updated.emit(current_day, current_hour, current_minute)
	print("⏰ TimeManager: Reset to Day 1, %d:00." % DAY_START_HOUR)
