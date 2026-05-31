extends Control

@onready var streak_label: Label = $CanvasLayer/Panel/VBoxContainer/StreakLabel
@onready var coin_label: Label = $CanvasLayer/Panel/VBoxContainer/CoinLabel
@onready var claim_button: Button = $CanvasLayer/Panel/VBoxContainer/ClaimButton

func _ready() -> void:
	claim_button.pressed.connect(_on_claim_pressed)
	var save_data: Dictionary = SaveSystem.get_data()
	streak_label.text = "Day %d Streak" % save_data["daily"]["streak"]
	var reward_coins: int = 10 + (save_data["daily"]["streak"] *5)
	coin_label.text = "🎁 +%d Coins" % reward_coins

func _on_claim_pressed() -> void:
	SaveSystem.claim_daily_reward()
	NavigationManager.pop_overlay()
