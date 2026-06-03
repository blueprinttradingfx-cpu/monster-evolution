extends Control

# BottomNav component - Navigation bar for main screens
# Per Screen Flow Section 14: UI System Architecture

signal tab_changed(tab_name: String)

@onready var _safe_area_container: MarginContainer = $SafeAreaContainer
@onready var _home_button: Button = $SafeAreaContainer/HBoxContainer/HomeButton
@onready var _collection_button: Button = $SafeAreaContainer/HBoxContainer/CollectionButton
@onready var _shop_button: Button = $SafeAreaContainer/HBoxContainer/ShopButton
@onready var _mini_games_button: Button = $SafeAreaContainer/HBoxContainer/MiniGamesButton

var _current_tab: String = "Home"

func _ready() -> void:
	_connect_signals()
	_update_safe_area()
	_set_active_tab("Home")

func _connect_signals() -> void:
	_home_button.pressed.connect(_on_home_pressed)
	_collection_button.pressed.connect(_on_collection_pressed)
	_shop_button.pressed.connect(_on_shop_pressed)
	_mini_games_button.pressed.connect(_on_mini_games_pressed)
	
	# Listen for GameManager screen changes to update active tab
	if GameManager:
		GameManager.screen_changed.connect(_on_screen_changed)

func _update_safe_area() -> void:
	# Respect device notches per AGENTS.md Section 4.2
	var safe_area: Rect2i = DisplayServer.get_display_safe_area()
	if safe_area != Rect2i():
		_safe_area_container.add_theme_constant_override("margin_bottom", safe_area.end.y - DisplayServer.window_get_size().y)

func _on_home_pressed() -> void:
	_set_active_tab("Home")
	tab_changed.emit("Home")
	if GameManager:
		GameManager.change_screen("Home")

func _on_collection_pressed() -> void:
	_set_active_tab("Collection")
	tab_changed.emit("Collection")
	if GameManager:
		GameManager.change_screen("Collection")

func _on_shop_pressed() -> void:
	_set_active_tab("Shop")
	tab_changed.emit("Shop")
	if GameManager:
		GameManager.change_screen("Shop")

func _on_mini_games_pressed() -> void:
	_set_active_tab("MiniGames")
	tab_changed.emit("MiniGames")
	if GameManager:
		GameManager.change_screen("MiniGame")

func _on_screen_changed(screen_name: String) -> void:
	# Update active tab based on current screen
	match screen_name:
		"Home":
			_set_active_tab("Home")
		"Collection":
			_set_active_tab("Collection")
		"Shop":
			_set_active_tab("Shop")
		"MiniGame", "MiniGames":
			_set_active_tab("MiniGames")

func _set_active_tab(tab_name: String) -> void:
	_current_tab = tab_name
	
	# Reset all buttons
	_home_button.modulate = Color.WHITE
	_collection_button.modulate = Color.WHITE
	_shop_button.modulate = Color.WHITE
	_mini_games_button.modulate = Color.WHITE
	
	# Highlight active button
	match tab_name:
		"Home":
			_home_button.modulate = Color(0.2, 0.6, 1.0)  # Blue highlight
		"Collection":
			_collection_button.modulate = Color(0.2, 0.6, 1.0)
		"Shop":
			_shop_button.modulate = Color(0.2, 0.6, 1.0)
		"MiniGames":
			_mini_games_button.modulate = Color(0.2, 0.6, 1.0)
