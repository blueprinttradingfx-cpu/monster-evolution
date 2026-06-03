extends Control

# MonsterCard component - Displays monster in grid view
# Per UI Wireframe Section 4 and Screen Flow Section 4

signal card_pressed(monsterId: String)

@onready var _background: Panel = $Background
@onready var _icon: TextureRect = $VBoxContainer/IconContainer/Icon
@onready var _species_label: Label = $VBoxContainer/InfoContainer/SpeciesLabel
@onready var _stage_label: Label = $VBoxContainer/InfoContainer/StageBadge
@onready var _active_indicator: ColorRect = $ActiveIndicator

var _monster_id: String = ""

func _ready() -> void:
	gui_input.connect(_on_gui_input)

func set_monster(monster_id: String, monster_data: Dictionary) -> void:
	_monster_id = monster_id
	
	# Set species label
	if monster_data.has("speciesId"):
		_species_label.text = monster_data.speciesId.capitalize()
	
	# Set stage label
	if monster_data.has("stageId"):
		_stage_label.text = _get_stage_name(monster_data.stageId)
	
	# Set icon (placeholder - will load from sprite in TICKET-30)
	_icon.texture = null
	
	# Set active indicator
	if GameManager and GameManager.active_monster_id == monster_id:
		_active_indicator.visible = true
	else:
		_active_indicator.visible = false

func set_active(is_active: bool) -> void:
	_active_indicator.visible = is_active

func _get_stage_name(stage_id: String) -> String:
	match stage_id:
		"stage_0": return "Egg"
		"stage_1": return "Baby"
		"stage_2": return "Kid"
		"stage_3": return "Adult"
		"stage_4": return "Elder"
		_: return "?"

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		card_pressed.emit(_monster_id)
