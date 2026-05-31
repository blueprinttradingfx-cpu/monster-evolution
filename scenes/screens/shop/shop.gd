extends Control

@onready var coins_label: Label = $SafeArea/VBoxContainer/CoinsLabel
@onready var buy_egg_button: Button = $SafeArea/VBoxContainer/BuyEggButton
@onready var buy_coins_button: Button = $SafeArea/VBoxContainer/BuyCoinsButton
@onready var back_button: Button = $SafeArea/VBoxContainer/BackButton

func _ready() -> void:
	buy_egg_button.pressed.connect(_on_buy_egg)
	buy_coins_button.pressed.connect(_on_buy_coins)
	back_button.pressed.connect(_on_back_pressed)
	_update_ui()

func _update_ui() -> void:
	var save_data: Dictionary = SaveSystem.get_data()
	coins_label.text = "Your Coins: %d" % save_data["economy"]["coins"]

func _on_buy_egg() -> void:
	var save_data: Dictionary = SaveSystem.get_data()
	if save_data["economy"]["coins"] >= 20:
		SaveSystem.add_coins(-20)
		SaveSystem.add_to_inventory("egg")
		SaveSystem.save_game()
		_update_ui()

func _on_buy_coins() -> void:
	# For MVP, just add coins
	SaveSystem.add_coins(50)
	SaveSystem.save_game()
	_update_ui()

func _on_back_pressed() -> void:
	GameState.go_to(GameState.Screen.MENU)
