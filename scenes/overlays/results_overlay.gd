extends Control

@onready var title_label: Label = $CanvasLayer/Panel/VBoxContainer/TitleLabel
@onready var coins_label: Label = $CanvasLayer/Panel/VBoxContainer/CoinsLabel
@onready var eggs_label: Label = $CanvasLayer/Panel/VBoxContainer/EggsLabel
@onready var continue_button: Button = $CanvasLayer/Panel/VBoxContainer/ContinueButton

func _ready():
	RewardSystem.rewards_ready.connect(_on_rewards_ready)
	continue_button.pressed.connect(_on_continue_pressed)

func _on_rewards_ready(rewards: Dictionary):
	_show_rewards(rewards)
	RewardSystem.apply_rewards(rewards)
	RewardSystem.increase_streak()

func _show_rewards(rewards: Dictionary):
	title_label.text = "Round Complete!"
	coins_label.text = "+%d Coins" % rewards.get("coins", 0)
	if rewards.get("eggs", 0) > 0:
		eggs_label.text = "+%d Eggs" % rewards.get("eggs", 0)
		eggs_label.visible = true
	else:
		eggs_label.visible = false

func _on_continue_pressed():
	NavigationManager.pop_overlay()
	GameState.go_to(GameState.Screen.MERGE)
