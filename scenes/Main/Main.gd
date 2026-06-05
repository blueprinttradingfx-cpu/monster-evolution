extends Control

# Main bootstrap scene - App initialization and loading
# Per Screen Flow Section 11: Loading/Bootstrap

@onready var _title_label: Label = $LoadingContainer/VBoxContainer/TitleLabel
@onready var _loading_label: Label = $LoadingContainer/VBoxContainer/LoadingLabel
@onready var _progress_bar: ProgressBar = $LoadingContainer/VBoxContainer/ProgressBar

func _ready() -> void:
	print("Main bootstrap scene loaded")
	_start_loading_flow()

func _start_loading_flow() -> void:
	_update_progress(0.1, "Initializing...")
	await get_tree().process_frame
	
	_update_progress(0.3, "Loading save data...")
	# SaveManager already loads save in _ready, but we wait to ensure it's done
	await get_tree().process_frame
	
	_update_progress(0.5, "Initializing systems...")
	await _initialize_systems()
	
	_update_progress(0.7, "Loading resources...")
	await _load_resources()
	
	_update_progress(0.9, "Setting up game state...")
	await _setup_game_state()
	
	_update_progress(1.0, "Complete!")
	await get_tree().create_timer(0.5).timeout
	
	# Transition to Home screen
	_transition_to_home()

func _on_screen_changed(screen_name: String):
	print("[Main] _on_screen_changed() called with screen_name: ", screen_name)
	var scene_path: String
	match screen_name:
		"Home":
			scene_path = "res://scenes/screens/home/home.tscn"
		"Collection":
			scene_path = "res://scenes/screens/collection/collection.tscn"
		"Shop":
			scene_path = "res://scenes/screens/shop/shop.tscn"
		"MiniGame":
			scene_path = "res://scenes/screens/mini_game_hub/MiniGameHub.tscn"
		"Hatch":
			scene_path = "res://scenes/screens/hatch/HatchScene.tscn"
		"Evolution":
			scene_path = "res://scenes/screens/evolution/EvolutionConfirmation.tscn"
		"MemorySetup":
			scene_path = "res://scenes/screens/memory-setup/memory-setup.tscn"
		"Memory":
			scene_path = "res://scenes/screens/memory/memory.tscn"
		"CreatureDetail":
			scene_path = "res://scenes/screens/creature-detail/creature-detail.tscn"
		_:
			print("[Main] Unknown screen: ", screen_name)
			return
	
	print("[Main] Changing scene to path: ", scene_path)
	get_tree().change_scene_to_file(scene_path)

func _initialize_systems() -> void:
	# All autoloads are already initialized by Godot
	# This is a placeholder for any additional initialization needed
	print("Systems initialized")

func _load_resources() -> void:
	# Placeholder for resource loading
	# Will load species, eggs, cosmetics, etc. from .tres files
	print("Resources loaded")

func _setup_game_state() -> void:
	# Check if player has any monsters
	var monster_ids: Array = MonsterManager.get_owned_monster_ids() if MonsterManager else []
	
	if monster_ids.is_empty():
		# New player flow - give starter egg
		print("New player detected - giving starter egg")
		if MonsterManager:
			MonsterManager.add_egg("dino_egg")
	else:
		# Set active monster if not set
		var active_id: String = GameManager.activeMonsterId if GameManager else ""
		if active_id.is_empty() and not monster_ids.is_empty():
			GameManager.set_active_monster(monster_ids[0])
			print("Set active monster to: ", monster_ids[0])
	
	print("Game state setup complete")

func _transition_to_home() -> void:
	print("Transitioning to Home screen via GameState")
	GameState.go_to(GameState.Screen.MENU)

func _update_progress(value: float, text: String) -> void:
	if _progress_bar:
		_progress_bar.value = value
	if _loading_label:
		_loading_label.text = text
