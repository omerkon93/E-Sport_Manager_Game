extends Control
class_name SettingsMenu

# --- SIGNALS ---
signal close_requested

# --- AUDIO BUS INDICES ---
var _bus_master: int
var _bus_music: int
var _bus_sfx: int

# --- UI NODES: SLIDERS ---
@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider

# --- UI NODES: LABELS ---
@onready var master_value: Label = %MasterValue
@onready var music_value: Label = %MusicValue
@onready var sfx_value: Label = %SFXValue

# --- UI NODES: TOGGLES & BUTTONS ---
@onready var fullscreen_check: CheckBox = %FullscreenCheck
@onready var time_format_check: CheckBox = %TimeFormatCheck

# Data Management Buttons
@onready var back_btn: Button = %BackButton
@onready var reset_btn: Button = %ResetButton
@onready var save_btn: Button = %SaveButton            # "Save As..."
@onready var quick_save_btn: Button = %QuickSaveButton # "Quick Save"
@onready var load_btn: Button = %LoadButton            # "Load / Switch Slot"

# --- SUB-MENUS ---
# Ensure you added the SaveSelectionMenu scene as a child of this node!
@onready var save_selection_menu: Control = $SaveSelectionMenu 

# ==============================================================================
# 1. LIFECYCLE
# ==============================================================================
func _ready() -> void:
	# 1. Audio Setup
	_bus_master = AudioServer.get_bus_index("Master")
	_bus_music = AudioServer.get_bus_index("Music")
	_bus_sfx = AudioServer.get_bus_index("SFX")
	
	if master_slider: master_slider.value_changed.connect(_on_volume_changed.bind(_bus_master, master_value))
	if music_slider: music_slider.value_changed.connect(_on_volume_changed.bind(_bus_music, music_value))
	if sfx_slider: sfx_slider.value_changed.connect(_on_volume_changed.bind(_bus_sfx, sfx_value))
	
	# 2. Display Setup
	if fullscreen_check: fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	if time_format_check: time_format_check.toggled.connect(_on_time_format_toggled)
	
	# 3. Button Connections
	if back_btn: back_btn.pressed.connect(close)
	if reset_btn: reset_btn.pressed.connect(_on_reset_pressed)
	if quick_save_btn: quick_save_btn.pressed.connect(_on_quick_save_pressed)
	SignalBus.open_settings_requested.connect(open)
	
	if save_btn: 
		save_btn.pressed.connect(func(): 
			if save_selection_menu: save_selection_menu.open(true)
		)
		
	if load_btn: 
		load_btn.pressed.connect(func(): 
			if save_selection_menu: save_selection_menu.open(false)
			)
			
	# 4. Global Signal Connections (NEW)
	# Listen for when a game is loaded so we can refresh the world
	if SaveManager.has_signal("game_loaded"):
		SaveManager.game_loaded.connect(_on_game_loaded)
	
	# 5. Initialize
	hide()

# ==============================================================================
# 2. PUBLIC METHODS
# ==============================================================================
func open() -> void:
	show()
	_load_current_settings()
	_refresh_button_states()

func close() -> void:
	hide()
	close_requested.emit()

# ==============================================================================
# 3. PRIVATE HELPER METHODS
# ==============================================================================
func _load_current_settings() -> void:
	# Audio
	var vol_master = db_to_linear(AudioServer.get_bus_volume_db(_bus_master))
	var vol_music = db_to_linear(AudioServer.get_bus_volume_db(_bus_music))
	var vol_sfx = db_to_linear(AudioServer.get_bus_volume_db(_bus_sfx))
	
	if master_slider: master_slider.value = vol_master
	if music_slider: music_slider.value = vol_music
	if sfx_slider: sfx_slider.value = vol_sfx
	
	_update_label(master_value, vol_master)
	_update_label(music_value, vol_music)
	_update_label(sfx_value, vol_sfx)
	
	# Toggles
	var mode = DisplayServer.window_get_mode()
	if fullscreen_check: 
		fullscreen_check.button_pressed = (mode == DisplayServer.WINDOW_MODE_FULLSCREEN)
	if time_format_check:
		time_format_check.button_pressed = SettingsManager.get_setting("time_format_24h", true)

func _refresh_button_states() -> void:
	var slot_id = SaveManager.current_slot_id
	var save_exists = SaveManager.save_file_exists(slot_id)
	
	# RESET Button: Correct (Can only wipe if data exists)
	if reset_btn: 
		reset_btn.disabled = not save_exists
		reset_btn.text = "Reset Slot " + str(slot_id)
	
	# LOAD Button: CHANGED -> Always enabled so user can open menu to switch slots
	if load_btn:
		load_btn.disabled = false 
		load_btn.text = "Load / Switch Slot"
		
	# SAVE AS Button: Correct (Always enabled)
	if save_btn:
		save_btn.text = "Save As..."
		
	# QUICK SAVE: Correct
	if quick_save_btn:
		quick_save_btn.text = "Quick Save (Slot %d)" % slot_id
		quick_save_btn.disabled = false

func _update_label(label: Label, value: float) -> void:
	if label: label.text = str(int(value * 100)) + "%"

# ==============================================================================
# 4. ACTION CALLBACKS
# ==============================================================================
func _on_game_loaded() -> void:
	print("🔄 SettingsMenu: Game Loaded signal received. Reloading scene...")
	# 1. Close this menu
	close()
	
	# 2. Unpause the game (if the menu paused it)
	get_tree().paused = false
	
	# 3. Reload the current scene
	# This forces all nodes (Player, Chests, etc.) to run _ready() again
	# and fetch the fresh data from the Singletons (ProgressionManager, etc.)
	get_tree().reload_current_scene()

func _on_quick_save_pressed() -> void:
	# 1. Perform Save
	SaveManager.save_game()
	
	# 2. Visual Feedback
	quick_save_btn.text = "Saved!"
	quick_save_btn.disabled = true
	
	# 3. Refresh other buttons (Reset/Load might become available now)
	_refresh_button_states()
	
	# 4. Reset Button Text after delay
	await get_tree().create_timer(1.0).timeout
	if quick_save_btn:
		quick_save_btn.disabled = false
		quick_save_btn.text = "Quick Save (Slot %d)" % SaveManager.current_slot_id

func _on_reset_pressed() -> void:
	# 1. Delete Save
	SaveManager.delete_save(SaveManager.current_slot_id)
	
	# 2. Visual Feedback
	if reset_btn: reset_btn.text = "Wiped!"
	
	# 3. Disable buttons immediately
	_refresh_button_states()

func _on_volume_changed(value: float, bus_idx: int, label: Label) -> void:
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))
	AudioServer.set_bus_mute(bus_idx, value < 0.05)
	_update_label(label, value)

func _on_fullscreen_toggled(is_fullscreen: bool) -> void:
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_time_format_toggled(toggled_on: bool) -> void:
	SettingsManager.set_setting("time_format_24h", toggled_on)
