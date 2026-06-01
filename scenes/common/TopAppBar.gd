extends PanelContainer
class_name TopAppBar

@onready var coins_label = $HBoxContainer/CurrencyContainer/CurrencyHBox/Coins/CoinsLabel
@onready var eggs_label = $HBoxContainer/CurrencyContainer/CurrencyHBox/Eggs/EggsLabel

func _ready() -> void:
	_load_from_save_data()

func _load_from_save_data() -> void:
	var save_data: Dictionary = SaveSystem.get_data()
	var coins: int = save_data.get("economy", {}).get("coins", 0)
	var eggs: int = save_data.get("inventory", {}).get("egg", 0)
	set_currency(coins, eggs)

func set_currency(coins: int, eggs: int) -> void:
	coins_label.text = str(coins)
	eggs_label.text = str(eggs)

func set_coins(amount: int) -> void:
	coins_label.text = str(amount)

func set_eggs(amount: int) -> void:
	eggs_label.text = str(amount)
