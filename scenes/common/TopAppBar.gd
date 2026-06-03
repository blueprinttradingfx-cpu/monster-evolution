extends PanelContainer
class_name TopAppBar

signal settings_clicked()

@onready var coins_label = $HBoxContainer/LeftGroup/CoinDisplay/CoinsLabel
@onready var settings_button = $HBoxContainer/RightGroup/SettingsButton

func _ready() -> void:
	print("[TopAppBar] _ready() called")
	_load_from_save_data()
	if EconomyManager:
		EconomyManager.coins_changed.connect(_on_coins_changed)
	print("[TopAppBar] Connecting settings button pressed")
	settings_button.pressed.connect(_on_settings_clicked)

func _on_coins_changed(new_coins: int) -> void:
	print("[TopAppBar] _on_coins_changed() called with coins: ", new_coins)
	coins_label.text = str(new_coins)

func _on_settings_clicked() -> void:
	print("[TopAppBar] Settings button clicked! Emitting settings_clicked")
	settings_clicked.emit()

func _load_from_save_data() -> void:
	print("[TopAppBar] _load_from_save_data() called")
	if EconomyManager:
		set_coins(EconomyManager.get_coins())

func set_coins(amount: int) -> void:
	print("[TopAppBar] set_coins() called with amount: ", amount)
	coins_label.text = str(amount)
