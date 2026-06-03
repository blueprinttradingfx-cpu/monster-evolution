extends Control

# Collection Screen - Displays all owned monsters in grid view
# Per Screen Flow Section 4 and UI Wireframe Section 4

signal set_active_requested(monsterId: String)
signal rename_requested(monsterId: String)
signal view_details_requested(monsterId: String)

@onready var top_appbar: Control = $SafeArea/VBoxContainer/TopAppBar
@onready var bottom_nav: BottomNav = $SafeArea/VBoxContainer/BottomNav
@onready var monster_grid: GridContainer = $SafeArea/VBoxContainer/MainContent/MonsterGridScroll/MonsterGrid
@onready var detail_panel: VBoxContainer = $SafeArea/VBoxContainer/MainContent/DetailPanel
@onready var monster_display: Control = $SafeArea/VBoxContainer/MainContent/DetailPanel/MonsterDisplay
@onready var name_label: Label = $SafeArea/VBoxContainer/MainContent/DetailPanel/InfoLabels/NameLabel
@onready var species_label: Label = $SafeArea/VBoxContainer/MainContent/DetailPanel/InfoLabels/SpeciesLabel
@onready var stage_label: Label = $SafeArea/VBoxContainer/MainContent/DetailPanel/InfoLabels/StageLabel
@onready var morph_label: Label = $SafeArea/VBoxContainer/MainContent/DetailPanel/InfoLabels/MorphLabel
@onready var set_active_button: Button = $SafeArea/VBoxContainer/MainContent/DetailPanel/ActionButtons/SetActiveButton
@onready var rename_button: Button = $SafeArea/VBoxContainer/MainContent/DetailPanel/ActionButtons/RenameButton
@onready var view_details_button: Button = $SafeArea/VBoxContainer/MainContent/DetailPanel/ActionButtons/ViewDetailsButton
@onready var empty_state_label: Label = $SafeArea/VBoxContainer/MainContent/MonsterGridScroll/MonsterGrid/EmptyStateLabel

const MONSTER_CARD_SCENE: PackedScene = preload("res://scenes/common/MonsterCard/MonsterCard.tscn")
const CARD_POOL_SIZE: int = 50

var card_pool: Array = []
var selected_monster_id: String = ""

func _ready() -> void:
	_connect_signals()
	_warm_card_pool()
	_load_monsters()
	bottom_nav.set_active("Collection")

func _connect_signals() -> void:
	set_active_button.pressed.connect(_on_set_active_pressed)
	rename_button.pressed.connect(_on_rename_pressed)
	view_details_button.pressed.connect(_on_view_details_pressed)

func _warm_card_pool() -> void:
	for i in range(CARD_POOL_SIZE):
		var card: Control = MONSTER_CARD_SCENE.instantiate()
		card.visible = false
		add_child(card)
		card_pool.append(card)

func _get_card() -> Control:
	if card_pool.is_empty():
		push_error("Card pool exhausted")
		return MONSTER_CARD_SCENE.instantiate()
	var card: Control = card_pool.pop_back()
	card.visible = true
	return card

func _return_card(card: Control) -> void:
	card.visible = false
	card_pool.append(card)

func _load_monsters() -> void:
	# Clear existing cards
	for child in monster_grid.get_children():
		if child != empty_state_label:
			monster_grid.remove_child(child)
			_return_card(child)
	
	# Load monsters from MonsterManager
	var monsters: Array = MonsterManager.get_all_monsters()
	
	if monsters.is_empty():
		empty_state_label.visible = true
		detail_panel.visible = false
		return
	
	empty_state_label.visible = false
	detail_panel.visible = true
	
	# Create cards for each monster
	for monster_data in monsters:
		if monster_data.has("id"):
			var card: Control = _get_card()
			monster_grid.add_child(card)
			if card.has_signal("card_pressed"):
				card.card_pressed.connect(_on_card_pressed)
			if card.has_method("set_monster"):
				card.set_monster(monster_data.id, monster_data)
	
	# Select first monster if available
	if not monsters.is_empty() and monsters[0].has("id"):
		_select_monster(monsters[0].id)

func _select_monster(monster_id: String) -> void:
	selected_monster_id = monster_id
	
	var monster_data: Dictionary = MonsterManager.get_monster(monster_id)
	
	# Update detail panel
	if monster_data.has("speciesId"):
		species_label.text = "Selected: %s" % monster_data.speciesId.capitalize()
	
	if monster_data.has("stageId"):
		stage_label.text = "Stage: %s" % _get_stage_name(monster_data.stageId)
	
	var morph_id: String = monster_data.get("morphId", "")
	morph_label.text = "Morph: %s" % (morph_id.capitalize() if not morph_id.is_empty() else "None")
	
	name_label.text = "Monster %s" % monster_id.substr(8, 8)
	
	# Update monster display
	if monster_display.has_method("set_monster"):
		monster_display.set_monster(monster_data)
	
	# Update card active indicators
	for child in monster_grid.get_children():
		if child is MonsterCard:
			child.set_active(child.monster_id == monster_id)

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
	if selected_monster_id != "":
		MonsterManager.set_active_monster(selected_monster_id)
		set_active_requested.emit(selected_monster_id)
		_load_monsters()  # Refresh to update active indicators

func _on_rename_pressed() -> void:
	if selected_monster_id != "":
		rename_requested.emit(selected_monster_id)

func _on_view_details_pressed() -> void:
	if selected_monster_id != "":
		if GameState:
			GameState.go_to(GameState.Screen.CREATURE_DETAIL, {"creature_id": selected_monster_id})

func refresh() -> void:
	_load_monsters()
