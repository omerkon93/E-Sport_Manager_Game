extends Node

const TICKETS_PATH = "res://game_data/dialogue/"
var all_tickets: Array[DialogueSequence] = []

func _ready():
	_load_ticket_database()

func _load_ticket_database() -> void:
	_scan_directory_recursive(TICKETS_PATH)
	print("📁 DialogueDatabase: Loaded %d tickets." % all_tickets.size())

func _scan_directory_recursive(path: String) -> void:
	var dir = DirAccess.open(path)
	if dir:
		for file_name in dir.get_files():
			if file_name.ends_with(".tres") or file_name.ends_with(".res"):
				var res = load(path + file_name)
				if res is DialogueSequence:
					if res.parent_action != null:
						all_tickets.append(res)
					else:
						push_warning("DialogueDatabase: Skipped '%s' because parent_action is empty!" % file_name)
					
		for dir_name in dir.get_directories():
			_scan_directory_recursive(path + dir_name + "/")

# We put the progression check HERE to keep the UI decoupled!
func is_option_unlocked(opt) -> bool:
	if opt.required_story_flag != null and not ProgressionManager.get_flag(opt.required_story_flag.id):
		return false
	return true
