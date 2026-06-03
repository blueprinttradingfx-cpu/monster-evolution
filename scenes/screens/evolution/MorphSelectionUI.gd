extends Control

# Morph Selection UI - Overlay for selecting morph when evolving from Adult to Elder
# Per TICKET-18

# --- SIGNALS ---
signal morph_selected(morphId: String)
signal selection_cancelled()

# --- NODES ---
@onready var morph_options_container: HBoxContainer = $MainContent/MorphOptions
@onready var cancel_button: Button = $MainContent/CancelButton

# --- VARIABLES ---
var _monster_id: String = ""
var _selected_morph_id: String = ""

func _ready() -> void:
	_connect_signals()

func _connect_signals() -> void:
	cancel_button.pressed.connect(_on_cancel_pressed)

func open(monster_id: String) -> void:
	_monster_id = monster_id
	_clear_morph_options()
	_populate_morph_options()
	_selected_morph_id = ""
	visible = true

func _clear_morph_options() -> void:
	for child in morph_options_container.get_children():
		child.queue_free()

func _populate_morph_options() -> void:
	if not MonsterManager or _monster_id.is_empty():
		return
	
	var monster_data: Dictionary = MonsterManager.get_monster(_monster_id)
	if monster_data.is_empty():
		return
	
	var species_id: String = monster_data.get("speciesId", "")
	var stage_id: String = monster_data.get("stageId", "stage_1")
	var stage_num: int = _get_stage_number(stage_id)
	
	var available_morphs: Array = MonsterManager.get_available_morphs(species_id, stage_num)
	
	for morph in available_morphs:
		_add_morph_option(morph)
	
	# Add default option
	_add_default_morph_option()

func _add_morph_option(morph: Dictionary) -> void:
	var button: Button = Button.new()
	button.text = morph.get("name", "")
	button.custom_minimum_size = Vector2(180, 100)
	button.pressed.connect(func(): _on_morph_selected(morph.get("id", "")))
	morph_options_container.add_child(button)

func _add_default_morph_option() -> void:
	var button: Button = Button.new()
	button.text = "Default"
	button.custom_minimum_size = Vector2(180, 100)
	button.pressed.connect(func(): _on_morph_selected(""))
	morph_options_container.add_child(button)

func _on_morph_selected(morph_id: String) -> void:
	_selected_morph_id = morph_id
	if MonsterManager and _monster_id:
		MonsterManager.set_morph(_monster_id, morph_id)
	morph_selected.emit(morph_id)
	visible = false

func _on_cancel_pressed() -> void:
	selection_cancelled.emit()
	visible = false

func _get_stage_number(stage_id: String) -> int:
	match stage_id:
		"stage_0":
			return 0
		"stage_1":
			return 1
		"stage_2":
			return 2
		"stage_3":
			return 3
		"stage_4":
			return 4
		_:
			return 0
