extends Node

# Signals for the UI to listen to
signal research_started(item_id: String, duration: int)
signal research_progressed(item_id: String, remaining: int)
signal research_finished(item_id: String)

# Stores active research data
var active_research: Dictionary = {}
# Tracks the strict order of research (First in, First out)
var research_queue: Array[String] = []

func _ready() -> void:
	# We no longer connect to TimeManager here.
	# Research will only progress when manual_study() is called!
	pass

# --- PUBLIC API ---

func is_researching(item_id: String) -> bool:
	return active_research.has(item_id)

#func start_research(item: GameItem) -> void:
	#if active_research.has(item.id): return
	#
	#active_research[item.id] = {
		#"item_id": item.id,
		#"remaining": item.research_duration_minutes,
		#"total": item.research_duration_minutes
	#}
	#
	#research_queue.append(item.id) 
	#research_started.emit(item.id, item.research_duration_minutes)
	#
	#print("🔬 Research Queued: %s" % item.display_name)

func get_progress(item_id: String) -> float:
	if not active_research.has(item_id): return 0.0
	var data = active_research[item_id]
	return 1.0 - (float(data.remaining) / float(data.total))

#func get_global_research_speed() -> float:
	#var total_speed_percent = 0.0
	#for item in ItemManager.available_items:
		#if ProgressionManager.get_upgrade_level(item.id) > 0:
			#for effect in item.effects:
				#if effect != null and "stat" in effect and effect.stat == StatDefinition.StatType.RESEARCH_SPEED:
					#total_speed_percent += effect.amount
	#return 1.0 + total_speed_percent


# --- MANUAL STUDY LOGIC ---

## Call this function from your UI Button script!
## 'minutes_added' determines how much progress a single click gives.
#func manual_study(minutes_added: int = 1) -> void:
	#if research_queue.is_empty(): return
	#
	#var speed_mult = get_global_research_speed()
	#var effective_progress = int(minutes_added * speed_mult)
	#
	## Process the queue as long as we have progress to spend and items in line
	#while effective_progress > 0 and not research_queue.is_empty():
		## Only look at the first item in line
		#var current_id = research_queue[0]
		#var data = active_research[current_id]
		#
		#if effective_progress >= data.remaining:
			## We have enough time to finish this research completely!
			#effective_progress -= data.remaining
			#data.remaining = 0
			#research_progressed.emit(current_id, 0)
			#
			#_complete_research(current_id)
		#else:
			## Not enough time to finish, just apply the progress and stop
			#data.remaining -= effective_progress
			#effective_progress = 0 # This breaks the while loop
			#research_progressed.emit(current_id, data.remaining)


# --- INTERNAL LOGIC ---

#func _complete_research(id: String) -> void:
	#active_research.erase(id)
	#research_queue.pop_front()
	#
	#var item = ItemManager.find_item_by_id(id)
	#if item:
		#ItemManager.apply_level_up(item)
		#SignalBus.message_logged.emit("Research Complete: %s" % item.display_name, Color.GREEN)
		#research_finished.emit(id)

# ==============================================================================
# SAVE & LOAD
# ==============================================================================

func get_save_data() -> Dictionary:
	return {
		# duplicate(true) ensures we do a deep copy of the nested dictionary
		"active_research": active_research.duplicate(true),
		"research_queue": research_queue.duplicate(true)
	}

func load_save_data(data: Dictionary) -> void:
	active_research = data.get("active_research", {})
	
	# THE FIX: Grab the generic array first, then use .assign() to cast it to Array[String]
	var loaded_queue = data.get("research_queue", [])
	research_queue.assign(loaded_queue)
	
	# --- UI RESTORATION ---
	# We need to tell the UI about the research we just loaded so it can 
	# redraw the progress bars in your menus!
	for item_id in research_queue:
		if active_research.has(item_id):
			var r_data = active_research[item_id]
			# Tell the UI this exists
			research_started.emit(item_id, r_data.total)
			# Tell the UI exactly where the progress bar should be
			research_progressed.emit(item_id, r_data.remaining)

func reset() -> void:
	active_research.clear()
	research_queue.clear()
