extends Control

# Home Screen - Main hub screen where players interact with active monster
# Per Screen Flow Section 3 and UI Wireframe Section 3

signal evolve_requested()
signal play_requested()
signal collection_requested()
signal shop_requested()

@onready var pet_display: PetDisplay = $RootLayout/ScrollContainer/SafeArea/Main/CreatureSection/CreatureWrapper/PetDisplay
@onready var evolve_button: Button = $RootLayout/ScrollContainer/SafeArea/Main/ActionButtons/GridButtons/EvolveButton
@onready var play_button: Button = $RootLayout/ScrollContainer/SafeArea/Main/ActionButtons/GridButtons/PlayButton
@onready var collection_button: Button = $RootLayout/ScrollContainer/SafeArea/Main/ActionButtons/GridButtons/CollectionButton
@onready var shop_button: Button = $RootLayout/ScrollContainer/SafeArea/Main/ActionButtons/GridButtons/ShopButton
@onready var top_appbar: Control = $RootLayout/TopAppBar
@onready var bottom_nav: BottomNav = $RootLayout/BottomNav

func _ready() -> void:
	print("[Home] _ready() called")
	_connect_signals()
	_load_active_monster()
	
	if bottom_nav:
		bottom_nav.set_active("Home")

func _connect_signals() -> void:
	print("[Home] _connect_signals() called")
	if evolve_button:
		print("[Home] Connecting Evolve Button")
		evolve_button.pressed.connect(_on_evolve_pressed)
	if play_button:
		print("[Home] Connecting Play Button")
		play_button.pressed.connect(_on_play_pressed)
	if collection_button:
		print("[Home] Connecting Collection Button")
		collection_button.pressed.connect(_on_collection_pressed)
	if shop_button:
		print("[Home] Connecting Shop Button")
		shop_button.pressed.connect(_on_shop_pressed)
	if top_appbar:
		print("[Home] Connecting TopAppBar Settings Clicked")
		top_appbar.settings_clicked.connect(_on_settings_clicked)
	
	# Listen for GameManager active monster changes
	if GameManager:
		GameManager.active_monster_changed.connect(_on_active_monster_changed)
	
	# Listen for monster tap
	if pet_display:
		print("[Home] Connecting PetDisplay monster_tapped")
		pet_display.monster_tapped.connect(_on_monster_tapped)

func _load_active_monster() -> void:
	print("[Home] _load_active_monster() called")
	if not GameManager:
		print("[Home] GameManager not found!")
		return
	
	var active_monster_id: String = GameManager.activeMonsterId
	print("[Home] Active Monster ID: ", active_monster_id)
	if active_monster_id.is_empty():
		_show_no_monster_state()
		return
	
	if not MonsterManager:
		print("[Home] MonsterManager not found!")
		return
	
	var monster_data: Dictionary = MonsterManager.get_monster(active_monster_id)
	print("[Home] Monster Data: ", monster_data)
	if monster_data.is_empty():
		_show_no_monster_state()
		return
	
	_display_monster(monster_data)

func _display_monster(monster_data: Dictionary) -> void:
	print("[Home] _display_monster() called")
	if pet_display:
		pet_display.set_monster(monster_data)

func _show_no_monster_state() -> void:
	print("[Home] _show_no_monster_state() called")
	if pet_display:
		pet_display.modulate = Color.TRANSPARENT
	
	# Disable action buttons
	if evolve_button:
		evolve_button.disabled = true
	if play_button:
		play_button.disabled = true

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
	print("[Home] _on_evolve_pressed() called!")
	if GameManager:
		var active_monster_id: String = GameManager.activeMonsterId
		print("[Home] Evolve pressed with active monster: ", active_monster_id)
		if not active_monster_id.is_empty() and MonsterManager:
			# MonsterManager.evolve_monster(active_monster_id)
			_load_active_monster()
	print("[Home] Requesting GameState.go_to(GameState.Screen.EVOLUTION)")
	if GameState:
		GameState.go_to(GameState.Screen.EVOLUTION)

func _on_play_pressed() -> void:
	print("[Home] _on_play_pressed() called!")
	print("[Home] Requesting GameState.go_to(GameState.Screen.MINI_GAME_HUB)")
	if GameState:
		GameState.go_to(GameState.Screen.MINI_GAME_HUB)

func _on_collection_pressed() -> void:
	print("[Home] _on_collection_pressed() called!")
	print("[Home] Requesting GameState.go_to(GameState.Screen.COLLECTION)")
	if GameState:
		GameState.go_to(GameState.Screen.COLLECTION)

func _on_shop_pressed() -> void:
	print("[Home] _on_shop_pressed() called!")
	print("[Home] Requesting GameState.go_to(GameState.Screen.SHOP)")
	if GameState:
		GameState.go_to(GameState.Screen.SHOP)

func _on_settings_clicked() -> void:
	print("[Home] _on_settings_clicked() called!")
	print("[Home] Requesting GameState.go_to(GameState.Screen.SETTINGS)")
	if GameState:
		GameState.go_to(GameState.Screen.SETTINGS)

func _on_active_monster_changed(monsterId: String) -> void:
	print("[Home] _on_active_monster_changed() called with ID: ", monsterId)
	_load_active_monster()

func _on_monster_tapped() -> void:
	print("[Home] _on_monster_tapped() called!")
	# Trigger idle reaction animation
	# Sound effect to be added in TICKET-37 (Sound Effects)
	print("Monster tapped - reaction animation triggered")
