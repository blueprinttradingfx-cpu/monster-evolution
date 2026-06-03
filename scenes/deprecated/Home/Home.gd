extends Control

# Home Screen - Main hub screen where players interact with active monster
# Per Screen Flow Section 3 and UI Wireframe Section 3

signal evolve_requested()
signal play_requested()
signal collection_requested()
signal shop_requested()

var _monster_display: Control
var _monster_name_label: Label
var _stage_label: Label
var _interaction_hint_label: Label
var _evolve_button: Button
var _play_button: Button
var _collection_button: Button
var _shop_button: Button
var _egg_inventory_button: Button
var _test_hatch_button: Button
var _test_evolution_button: Button

func _ready() -> void:
	print("[DEBUG] Home scene ready, children count: ", get_child_count())
	for child in get_children():
		print("[DEBUG] Child: ", child.name, ", type: ", child.get_class())
		if child.has_method("get_child_count"):
			print("[DEBUG]  ", child.name, " children: ", child.get_child_count())
	
	# Assign nodes manually
	var main_content: VBoxContainer = get_node_or_null("MainContent")
	if main_content:
		_monster_display = main_content.get_node_or_null("MonsterDisplay")
		_monster_name_label = main_content.get_node_or_null("MonsterNameLabel")
		_stage_label = main_content.get_node_or_null("StageLabel")
		_interaction_hint_label = main_content.get_node_or_null("InteractionHintLabel")
		var action_buttons: HBoxContainer = main_content.get_node_or_null("ActionButtons")
		if action_buttons:
			_evolve_button = action_buttons.get_node_or_null("EvolveButton")
			_play_button = action_buttons.get_node_or_null("PlayButton")
			_collection_button = action_buttons.get_node_or_null("CollectionButton")
			_shop_button = action_buttons.get_node_or_null("ShopButton")
		_egg_inventory_button = main_content.get_node_or_null("EggInventoryButton")
		_test_hatch_button = main_content.get_node_or_null("TestHatchButton")
		_test_evolution_button = main_content.get_node_or_null("TestEvolutionButton")
	
	_connect_signals()
	_load_active_monster()

func _connect_signals() -> void:
	if _evolve_button:
		_evolve_button.pressed.connect(_on_evolve_pressed)
	if _play_button:
		_play_button.pressed.connect(_on_play_pressed)
	if _collection_button:
		_collection_button.pressed.connect(_on_collection_pressed)
	if _shop_button:
		_shop_button.pressed.connect(_on_shop_pressed)
	if _egg_inventory_button:
		_egg_inventory_button.pressed.connect(_on_egg_inventory_pressed)
	if _test_hatch_button:
		_test_hatch_button.pressed.connect(_on_test_hatch_pressed)
	if _test_evolution_button:
		_test_evolution_button.pressed.connect(_on_test_evolution_pressed)
	
	# Listen for GameManager active monster changes
	if GameManager:
		GameManager.active_monster_changed.connect(_on_active_monster_changed)
	
	# Listen for monster tap
	if _monster_display:
		_monster_display.monster_tapped.connect(_on_monster_tapped)

func _load_active_monster() -> void:
	if not GameManager:
		return
	
	var active_monster_id: String = GameManager.activeMonsterId
	if active_monster_id.is_empty():
		_show_no_monster_state()
		return
	
	if not MonsterManager:
		return
	
	var monster_data: Dictionary = MonsterManager.get_monster(active_monster_id)
	if monster_data.is_empty():
		_show_no_monster_state()
		return
	
	_display_monster(monster_data)

func _display_monster(monster_data: Dictionary) -> void:
	if _monster_display:
		_monster_display.set_monster(monster_data)
	
	if _monster_name_label and monster_data.has("speciesId"):
		_monster_name_label.text = _get_species_name(monster_data.speciesId)
	
	if _stage_label and monster_data.has("stageId"):
		_stage_label.text = _get_stage_name(monster_data.stageId)
	
	if _interaction_hint_label:
		_interaction_hint_label.text = "Tap to interact"

func _show_no_monster_state() -> void:
	if _monster_display:
		_monster_display.modulate = Color.TRANSPARENT
	
	if _monster_name_label:
		_monster_name_label.text = "No Active Monster"
	if _stage_label:
		_stage_label.text = ""
	if _interaction_hint_label:
		_interaction_hint_label.text = "Get an egg to start"
	
	# Disable action buttons
	if _evolve_button:
		_evolve_button.disabled = true
	if _play_button:
		_play_button.disabled = true

func _get_species_name(speciesId: String) -> String:
	# TODO: Load from Species resource when TICKET-09 implemented
	match speciesId:
		"dino":
			return "Dino"
		"slime":
			return "Slime"
		_:
			return speciesId.capitalize()

func _get_stage_name(stageId: String) -> String:
	# TODO: Load from EvolutionStage resource when TICKET-16 implemented
	match stageId:
		"stage_0":
			return "Egg"
		"stage_1":
			return "Baby"
		"stage_2":
			return "Kid"
		"stage_3":
			return "Adult"
		"stage_4":
			return "Elder"
		_:
			return "Unknown"

func _on_evolve_pressed() -> void:
	if GameManager:
		var active_monster_id: String = GameManager.activeMonsterId
		if not active_monster_id.is_empty() and MonsterManager:
			MonsterManager.evolve_monster(active_monster_id)
			_load_active_monster()

func _on_play_pressed() -> void:
	# Navigate to Mini Game Hub
	if GameManager:
		GameManager.change_screen("MiniGame")

func _on_collection_pressed() -> void:
	if GameManager:
		GameManager.change_screen("Collection")

func _on_shop_pressed() -> void:
	if GameManager:
		GameManager.change_screen("Shop")

func _on_active_monster_changed(monsterId: String) -> void:
	_load_active_monster()

func _on_monster_tapped() -> void:
	# Trigger idle reaction animation
	# Sound effect to be added in TICKET-37 (Sound Effects)
	print("Monster tapped - reaction animation triggered")

func _on_egg_inventory_pressed() -> void:
	# Show egg inventory popup
	_show_egg_inventory_popup()

func _show_egg_inventory_popup() -> void:
	# Instantiate egg inventory
	var egg_inventory_scene: PackedScene = load("res://scenes/Eggs/EggInventory.tscn")
	var egg_inventory: Control = egg_inventory_scene.instantiate()
	
	# Create a popup panel
	var popup: Window = Window.new()
	popup.title = "Egg Inventory"
	popup.size = Vector2(400, 400)
	popup.unresizable = true
	popup.close_requested.connect(popup.queue_free)
	popup.add_child(egg_inventory)
	
	# Connect hatch request signal
	egg_inventory.hatch_egg_requested.connect(func(owned_egg_id): _on_hatch_egg_requested(owned_egg_id, popup))
	
	# Add popup to scene
	add_child(popup)
	popup.popup_centered()

func _on_hatch_egg_requested(owned_egg_id: String, popup: Window) -> void:
	# Close popup and go to hatch scene
	popup.queue_free()
	if MonsterManager:
		var monster_id: String = MonsterManager.hatch_egg(owned_egg_id)
		if monster_id and GameManager:
			GameManager.set_active_monster(monster_id)

func _on_test_hatch_pressed() -> void:
	print("Test hatch button pressed!")
	if MonsterManager:
		var egg_id: String = MonsterManager.add_egg("dino_egg")
		var monster_id: String = MonsterManager.hatch_egg(egg_id)
		if monster_id and GameManager:
			GameManager.set_active_monster(monster_id)

func _on_test_evolution_pressed() -> void:
	print("Test evolution button pressed!")
	if GameManager:
		var active_monster_id: String = GameManager.activeMonsterId
		if active_monster_id.is_empty() and MonsterManager:
			# If no active monster, create a test one
			active_monster_id = MonsterManager.create_monster("dino", "dino_egg")
			GameManager.set_active_monster(active_monster_id)
		if MonsterManager and not active_monster_id.is_empty():
			MonsterManager.evolve_monster(active_monster_id)
			_load_active_monster()
