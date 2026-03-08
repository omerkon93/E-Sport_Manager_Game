extends CanvasLayer

# --- TICKET DATABASE ---
const TICKETS_PATH = "res://game_data/dialogue/"
var all_tickets: Array[DialogueSequence] = []

@onready var panel: PanelContainer = $PanelContainer
@onready var portrait_rect: TextureRect = $PanelContainer/HBoxContainer/Portrait
@onready var name_label: Label = $PanelContainer/HBoxContainer/VBoxContainer/NameLabel
@onready var text_label: RichTextLabel = $PanelContainer/HBoxContainer/VBoxContainer/TextLabel
@onready var option_list: VBoxContainer = $PanelContainer/HBoxContainer/OptionList
@onready var next_button: Button = $PanelContainer/HBoxContainer/NextButton

var current_sequence: DialogueSequence
var current_index: int = 0
var is_typing: bool = false

func _ready() -> void:
	visible = false 
	next_button.pressed.connect(_on_next_pressed)
	
	# Load all tickets into memory when the game boots
	_load_ticket_database()

# --- PUBLIC API ---
func start_dialogue(conv: DialogueSequence) -> void:
	if not conv or conv.slides.is_empty(): return
	
	current_sequence = conv
	current_index = 0
	visible = true
	_show_slide()

func get_random_ticket_for(action: ActionData) -> DialogueSequence:
	var valid_pool: Array[DialogueSequence] = []
	
	for ticket in all_tickets:
		# 1. Does it belong to this button?
		if ticket.parent_action.id != action.id:
			continue
			
		# 2. Do they have the required upgrade to see this ticket?
		if ticket.required_pool_upgrade and ProgressionManager.get_upgrade_level(ticket.required_pool_upgrade.id) <= 0:
			continue
			
		# 3. Do they have the required story flag?
		if ticket.required_story_flag and not ProgressionManager.get_flag(ticket.required_story_flag.id):
			continue
			
		valid_pool.append(ticket)
		
	if valid_pool.is_empty():
		return null
		
	return valid_pool.pick_random()

# --- INTERNAL LOGIC ---
func _load_ticket_database() -> void:
	# Start the recursive search at the root dialogue folder
	_scan_directory_recursive(TICKETS_PATH)
	print("📁 DialogueManager: Loaded %d tickets." % all_tickets.size())

func _scan_directory_recursive(path: String) -> void:
	var dir = DirAccess.open(path)
	if dir:
		# 1. First, check all the files in the CURRENT folder
		for file_name in dir.get_files():
			if file_name.ends_with(".tres") or file_name.ends_with(".res"):
				var res = load(path + file_name)
				if res is DialogueSequence:
					if res.parent_action != null:
						all_tickets.append(res)
					else:
						# Print a warning so you know exactly which file is missing its action!
						push_warning("DialogueManager: Skipped '%s' because parent_action is empty!" % file_name)
					
		# 2. Next, find any sub-folders and tell the script to scan those too!
		for dir_name in dir.get_directories():
			# Add the folder name and a trailing slash, then scan it
			_scan_directory_recursive(path + dir_name + "/")

func _show_slide() -> void:
	var slide: DialogueSlide = current_sequence.slides[current_index]
	
	# 1. Set Content
	name_label.text = slide.speaker_name
	text_label.text = slide.text
	
	if slide.portrait:
		portrait_rect.texture = slide.portrait
		portrait_rect.visible = true
	else:
		portrait_rect.visible = false
	
	# 2. Typewriter Effect
	text_label.visible_ratio = 0.0
	is_typing = true
	
	var tween = create_tween()
	var duration = slide.text.length() * 0.03
	tween.tween_property(text_label, "visible_ratio", 1.0, duration)
	tween.tween_callback(func(): is_typing = false)
	
	# 3. Clear old buttons (safely)
	for child in option_list.get_children():
		option_list.remove_child(child)
		child.queue_free()
	
	# 4. Spawn Options (Array Logic)
	if not slide.options.is_empty():
		next_button.visible = false
		_spawn_options(slide.options)
	else:
		next_button.visible = true

func _spawn_options(options_array: Array[DialogueOption]) -> void:
	for opt in options_array:
		# Safety check: Did you leave an empty element in the Inspector array?
		if opt == null: continue 

		# 1. CHECK UPGRADES: If an upgrade is slotted, do they have it?
		if opt.required_upgrade != null and ProgressionManager.get_upgrade_level(opt.required_upgrade.id) <= 0:
			continue # Skip this button!
			
		# 2. CHECK FLAGS: If a flag is slotted, is it true?
		if opt.required_story_flag != null and not ProgressionManager.get_flag(opt.required_story_flag.id):
			continue # Skip this button!

		# 3. SPAWN THE BUTTON
		var btn = Button.new()
		btn.text = opt.text
		btn.custom_minimum_size = Vector2(0, 40)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# Bind the target to the click event
		btn.pressed.connect(func(res=opt.target): _on_option_clicked(res))
		option_list.add_child(btn)

	# Fallback: If all options were locked and nothing spawned, show the Next/Close button
	if option_list.get_child_count() == 0:
		next_button.visible = true

func _on_option_clicked(target: Variant) -> void:
	# 1. NEW: Did the user leave the value <empty>? Close immediately!
	if target == null:
		_end_dialogue()
		return
		
	# 2. Is it a full Sequence? (The Book)
	if target is DialogueSequence:
		start_dialogue(target)
		
	# 3. Is it a single Slide? (The Page)
	elif target is DialogueSlide:
		var temp_sequence = DialogueSequence.new()
		var new_slides: Array[DialogueSlide] = []
		new_slides.append(target)
		temp_sequence.slides = new_slides
		start_dialogue(temp_sequence)

	# 4. Is it a Trigger? (The Signal)
	elif target is DialogueTrigger:
		if target.signal_id != "":
			SignalBus.dialogue_action.emit(target.signal_id)
		_end_dialogue()
		
	# 5. Is it Action Data? (The Transaction)
	elif target is ActionData:
		ActionManager.action_triggered.emit(target)
		if "trigger_signal_id" in target and target.trigger_signal_id != "":
			SignalBus.dialogue_action.emit(target.trigger_signal_id)
		_end_dialogue()

	else:
		_end_dialogue()

func _on_next_pressed() -> void:
	if is_typing:
		text_label.visible_ratio = 1.0
		is_typing = false
		return
		
	current_index += 1
	
	if current_index < current_sequence.slides.size():
		_show_slide()
	else:
		_end_dialogue()

func _end_dialogue() -> void:
	visible = false
	current_sequence = null
