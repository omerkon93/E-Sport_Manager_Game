extends CanvasLayer

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
	
	# Listen to the SignalBus to know when to wake up!
	SignalBus.dialogue_requested.connect(_on_dialogue_requested)

# --- PUBLIC API / EVENT LISTENER ---
func _on_dialogue_requested(conv: DialogueSequence) -> void:
	if not conv or conv.slides.is_empty(): return
	
	current_sequence = conv
	current_index = 0
	visible = true
	_show_slide()

# --- INTERNAL LOGIC ---
func _show_slide() -> void:
	var slide = current_sequence.slides[current_index]
	
	name_label.text = slide.speaker_name
	text_label.text = slide.text
	
	if slide.portrait:
		portrait_rect.texture = slide.portrait
		portrait_rect.visible = true
	else:
		portrait_rect.visible = false
	
	text_label.visible_ratio = 0.0
	is_typing = true
	
	var tween = create_tween()
	var duration = slide.text.length() * 0.03
	tween.tween_property(text_label, "visible_ratio", 1.0, duration)
	tween.tween_callback(func(): is_typing = false)
	
	for child in option_list.get_children():
		child.queue_free()
	
	if not slide.options.is_empty():
		next_button.visible = false
		_spawn_options(slide.options)
	else:
		next_button.visible = true

func _spawn_options(options_array: Array) -> void:
	for opt in options_array:
		if opt == null: continue 

		# The UI asks the Database if it can show this, decoupling it from Progression!
		if not DialogueDatabase.is_option_unlocked(opt):
			continue 

		var btn = Button.new()
		btn.text = opt.text
		btn.custom_minimum_size = Vector2(0, 40)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(func(res=opt.target): _on_option_clicked(res))
		option_list.add_child(btn)

	if option_list.get_child_count() == 0:
		next_button.visible = true

func _on_option_clicked(target: Variant) -> void:
	if target == null:
		_end_dialogue()
		return
		
	if target is DialogueSequence:
		_on_dialogue_requested(target)
		
	elif target is DialogueSlide:
		var temp_sequence = DialogueSequence.new()
		temp_sequence.slides = [target]
		_on_dialogue_requested(temp_sequence)

	elif target is DialogueTrigger:
		if target.signal_id != "":
			SignalBus.dialogue_action.emit(target.signal_id)
		_end_dialogue()
		
	elif target is ActionData:
		# Use the new static TransactionManager!
		TransactionManager.try_perform_action(target)
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
