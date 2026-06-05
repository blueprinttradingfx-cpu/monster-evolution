extends Control

# Collection Screen - Displays all owned monsters in grid view
# Per Screen Flow Section 4 and UI Wireframe Section 4

signal set_active_requested(monsterId: String)
signal rename_requested(monsterId: String)
signal view_details_requested(monsterId: String)

@onready var top_appbar: Control = $RootLayout/TopAppBar
@onready var bottom_nav: BottomNav = $RootLayout/BottomNav
@onready var monster_grid_scroll: ScrollContainer = %MonsterGridScroll
@onready var monster_grid: GridContainer = %MonsterGrid
@onready var detail_panel: VBoxContainer = %DetailPanel
@onready var monster_display: MonsterDisplay = $RootLayout/SafeArea/MainContent/DetailPanel/MonsterDisplay
@onready var name_label: Label = %NameLabel
@onready var species_label: Label = %SpeciesLabel
@onready var stage_label: Label = %StageLabel
@onready var morph_label: Label = %MorphLabel
@onready var set_active_button: Button = %SetActiveButton
@onready var rename_button: Button = %RenameButton
@onready var view_details_button: Button = %ViewDetailsButton
@onready var empty_state_label: Label = %EmptyStateLabel

const MONSTER_CARD_SCENE: PackedScene = preload("res://scenes/common/MonsterCard/MonsterCard.tscn")
const CARD_POOL_SIZE: int = 50

var card_pool: Array = []
var selected_monster_id: String = ""

func _ready() -> void:
	_connect_signals()
	_warm_card_pool()
	_load_monsters()
	if bottom_nav:
		bottom_nav.set_active("Collection")

func _connect_signals() -> void:
	if set_active_button:
		set_active_button.pressed.connect(_on_set_active_pressed)
	if rename_button:
		rename_button.pressed.connect(_on_rename_pressed)
	if view_details_button:
		view_details_button.pressed.connect(_on_view_details_pressed)

func _warm_card_pool() -> void:
	for i in range(CARD_POOL_SIZE):
		var card: Control = MONSTER_CARD_SCENE.instantiate()
		card.visible = false
		if card.has_signal("card_pressed"):
			card.card_pressed.connect(_on_card_pressed)
		card_pool.append(card)

func _get_card() -> Control:
	if card_pool.is_empty():
		push_error("Card pool exhausted")
		return MONSTER_CARD_SCENE.instantiate()
	return card_pool.pop_back()

func _return_card(card: Control) -> void:
	if card.get_parent() == monster_grid:
		monster_grid.remove_child(card)
	card.visible = false
	card_pool.append(card)

func _load_monsters() -> void:
	# Clear existing cards
	for child in monster_grid.get_children():
		monster_grid.remove_child(child)
		_return_card(child)
	
	# Load monsters from MonsterManager
	var monsters: Array = MonsterManager.get_all_monsters()
	
	if monsters.is_empty():
		empty_state_label.visible = true
		monster_grid_scroll.visible = false
		detail_panel.visible = false
		return
	
	empty_state_label.visible = false
	monster_grid_scroll.visible = true
	detail_panel.visible = true
	
	# Create cards for each monster
	for monster_data in monsters:
		if monster_data.has("id"):
			var card: Control = _get_card()
			monster_grid.add_child(card)
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
	
	name_label.text = monster_data.get("name", "Unnamed Monster")
	
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
