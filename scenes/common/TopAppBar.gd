extends PanelContainer
class_name TopAppBar

@onready var coins_label = $HBoxContainer/CurrencyContainer/CurrencyHBox/Coins/CoinsLabel
@onready var eggs_label = $HBoxContainer/CurrencyContainer/CurrencyHBox/Eggs/EggsLabel

func set_currency(coins: int, eggs: int) -> void:
	coins_label.text = str(coins)
	eggs_label.text = str(eggs)

func set_coins(amount: int) -> void:
	coins_label.text = str(amount)

func set_eggs(amount: int) -> void:
	eggs_label.text = str(amount)
