extends Control

# TopAppBar component - Top bar with coins display and settings button
# Per Screen Flow Section 14: UI System Architecture

signal settings_requested()

@onready var _safe_area_container: MarginContainer = $SafeAreaContainer
@onready var _coin_label: Label = $SafeAreaContainer/HBoxContainer/CoinContainer/CoinLabel
@onready var _settings_button: Button = $SafeAreaContainer/HBoxContainer/SettingsButton

func _ready() -> void:
	_connect_signals()
	_update_safe_area()
	_update_coin_display()

func _connect_signals() -> void:
	_settings_button.pressed.connect(_on_settings_pressed)
	
	# Listen for EconomyManager coin changes
	if EconomyManager:
		EconomyManager.coins_changed.connect(_on_coins_changed)

func _update_safe_area() -> void:
	# Respect device notches at top per AGENTS.md Section 4.2
	var safe_area: Rect2i = DisplayServer.get_display_safe_area()
	if safe_area != Rect2i():
		_safe_area_container.add_theme_constant_override("margin_top", safe_area.position.y)

func _on_settings_pressed() -> void:
	settings_requested.emit()

func _on_coins_changed(new_amount: int) -> void:
	_coin_label.text = str(new_amount)

func _update_coin_display() -> void:
	if EconomyManager:
		_coin_label.text = str(EconomyManager.get_coins())
