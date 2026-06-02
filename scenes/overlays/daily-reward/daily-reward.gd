extends Control

@onready var modal_card: PanelContainer = $ModalCard
@onready var claim_button: Button = $ModalCard/CardVBox/ClaimButton
@onready var coin_icon: Label = $ModalCard/CardVBox/RewardsGrid/CoinCard/CoinVBox/CoinIcon
@onready var egg_icon: Label = $ModalCard/CardVBox/RewardsGrid/EggCard/EggVBox/EggIcon
@onready var streak_label: Label = $ModalCard/CardVBox/StreakBadge/StreakLabel
@onready var coin_label: Label = $ModalCard/CardVBox/RewardsGrid/CoinCard/CoinVBox/CoinLabel
@onready var egg_label: Label = $ModalCard/CardVBox/RewardsGrid/EggCard/EggVBox/EggLabel
@onready var footer_label: Label = $ModalCard/CardVBox/FooterLabel
@onready var currency_label: Label = $TopBar/TopBarHBox/CurrencyBadge/CurrencyLabel

var _time := 0.0
var _reward_coins: int = 10

func _ready() -> void:
	_play_intro_animation()
	claim_button.pressed.connect(_on_claim_pressed)
	var save_data: Dictionary = SaveSystem.get_data()
	var streak: int = save_data.get("daily", {}).get("streak", 1)
	_reward_coins = 10 + (streak * 5)
	streak_label.text = "Day " + str(streak) + " Streak"
	coin_label.text = "+" + str(_reward_coins) + " Coins"
	footer_label.text = "Come back tomorrow for Day " + str(streak + 1) + "!"
	var coins: int = save_data.get("economy", {}).get("coins", 0)
	var eggs: int = save_data.get("inventory", {}).get("egg", 0)
	currency_label.text = str(coins) + " $  " + str(eggs) + " 🥚"

func _process(delta: float) -> void:
	_time += delta
	var float_speed_rad := 3.0 * TAU
	coin_icon.position.y = sin(_time * float_speed_rad) * -8.0
	egg_icon.position.y = sin(_time * float_speed_rad + PI) * -8.0

func _play_intro_animation() -> void:
	modal_card.scale = Vector2(0.8, 0.8)
	modal_card.modulate.a = 0.0
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(modal_card, "scale", Vector2(1.0, 1.0), 0.5)
	tween.parallel()
	tween.tween_property(modal_card, "modulate:a", 1.0, 0.3)

func _on_claim_pressed() -> void:
	var tween := create_tween()
	tween.tween_property(claim_button, "scale", Vector2(0.95, 0.95), 0.08)
	tween.tween_property(claim_button, "scale", Vector2(1.0, 1.0), 0.08)
	await tween.finished
	var fade_tween := create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.25)
	await fade_tween.finished
	SaveSystem.claim_daily_reward()
	var home_scene := get_tree().get_first_node_in_group("home_screen")
	if home_scene and home_scene.has_method("set_coins") and home_scene.has_method("set_eggs"):
		var save_data: Dictionary = SaveSystem.get_data()
		var coins: int = save_data.get("economy", {}).get("coins", 0)
		var eggs: int = save_data.get("inventory", {}).get("egg", 0)
		home_scene.set_coins(coins)
		home_scene.set_eggs(eggs)
	NavigationManager.pop_overlay()
