extends Control

# Collection Screen - Displays all owned monsters in grid view
# Per Screen Flow Section 4 and UI Wireframe Section 4

signal set_active_requested(monsterId: String)
signal rename_requested(monsterId: String)
signal view_details_requested(monsterId: String)

@onready var _monster_grid: GridContainer = $SafeArea/VBoxContainer/MainContainer/MonsterGridScroll/MonsterGrid
@onready var _detail_panel: VBoxContainer = $SafeArea/VBoxContainer/MainContainer/DetailPanel
@onready var _monster_display: Control = $SafeArea/VBoxContainer/MainContainer/DetailPanel/MonsterDisplay
@onready var _name_label: Label = $SafeArea/VBoxContainer/MainContainer/DetailPanel/InfoLabels/NameLabel
@onready var _species_label: Label = $SafeArea/VBoxContainer/MainContainer/DetailPanel/InfoLabels/SpeciesLabel
@onready var _stage_label: Label = $SafeArea/VBoxContainer/MainContainer/DetailPanel/InfoLabels/StageLabel
@onready var _set_active_button: Button = $SafeArea/VBoxContainer/MainContainer/DetailPanel/ActionButtons/SetActiveButton
@onready var _rename_button: Button = $SafeArea/VBoxContainer/MainContainer/DetailPanel/ActionButtons/RenameButton
@onready var _view_details_button: Button = $SafeArea/VBoxContainer/MainContainer/DetailPanel/ActionButtons/ViewDetailsButton
@onready var _empty_state_label: Label = $SafeArea/VBoxContainer/MainContainer/MonsterGridScroll/MonsterGrid/EmptyStateLabel

const MONSTER_CARD_SCENE: PackedScene = preload("res://scenes/common/MonsterCard/MonsterCard.tscn")
const CARD_POOL_SIZE: int = 50

var _card_pool: Array = []
var _selected_monster_id: String = ""

func _ready() -> void:
	_connect_signals()
	_warm_card_pool()
	_load_monsters()

func _connect_signals() -> void:
	_set_active_button.pressed.connect(_on_set_active_pressed)
	_rename_button.pressed.connect(_on_rename_pressed)
	_view_details_button.pressed.connect(_on_view_details_pressed)

func _warm_card_pool() -> void:
	for i in range(CARD_POOL_SIZE):
		var card: Control = MONSTER_CARD_SCENE.instantiate()
		card.visible = false
		add_child(card)
		_card_pool.append(card)

func _get_card() -> Control:
	if _card_pool.is_empty():
		push_error("Card pool exhausted")
		return MONSTER_CARD_SCENE.instantiate()
	var card: Control = _card_pool.pop_back()
	card.visible = true
	return card

func _return_card(card: Control) -> void:
	card.visible = false
	_card_pool.append(card)

func _load_monsters() -> void:
	# Clear existing cards
	for child in _monster_grid.get_children():
		if child != _empty_state_label:
			_return_card(child)
	
	# Load monsters from MonsterManager
	var monsters: Array = MonsterManager.get_all_monsters()
	
	if monsters.is_empty():
		_empty_state_label.visible = true
		_detail_panel.visible = false
		return
	
	_empty_state_label.visible = false
	_detail_panel.visible = true
	
	# Create cards for each monster
	for monster_data in monsters:
		if monster_data.has("id"):
			var card: Control = _get_card()
			_monster_grid.add_child(card)
			card.card_pressed.connect(_on_card_pressed)
			card.set_monster(monster_data.id, monster_data)
	
	# Select first monster if available
	if not monsters.is_empty() and monsters[0].has("id"):
		_select_monster(monsters[0].id)

func _select_monster(monster_id: String) -> void:
	_selected_monster_id = monster_id
	
	var monster_data: Dictionary = MonsterManager.get_monster(monster_id)
	
	# Update detail panel
	if monster_data.has("speciesId"):
		_species_label.text = "Species: %s" % monster_data.speciesId.capitalize()
	
	if monster_data.has("stageId"):
		_stage_label.text = "Stage: %s" % _get_stage_name(monster_data.stageId)
	
	_name_label.text = "Monster %s" % monster_id.substr(8, 8)
	
	# Update monster display
	if _monster_display.has_method("set_monster"):
		_monster_display.set_monster(monster_data)
	
	# Update card active indicators
	for child in _monster_grid.get_children():
		if child is Control and child.has_method("set_active"):
			child.set_active(child._monster_id == monster_id)

func _get_stage_name(stage_id: String) -> String:
	match stage_id:
		"stage_0": return "Egg"
		"stage_1": return "Baby"
		"stage_2": return "Kid"
		"stage_3": return "Adult"
		"stage_4": return "Elder"
		_: return "?"

func _on_card_pressed(monster_id: String) -> void:
	_select_monster(monster_id)

func _on_set_active_pressed() -> void:
	if _selected_monster_id != "":
		MonsterManager.set_active_monster(_selected_monster_id)
		set_active_requested.emit(_selected_monster_id)
		_load_monsters()  # Refresh to update active indicators

func _on_rename_pressed() -> void:
	if _selected_monster_id != "":
		rename_requested.emit(_selected_monster_id)

func _on_view_details_pressed() -> void:
	if _selected_monster_id != "":
		view_details_requested.emit(_selected_monster_id)

func refresh() -> void:
	_load_monsters()
