extends Control

@onready var monster_image: TextureRect = $MainContainer/RootVBox/CenterSection/CreatureContainer/MonsterImage
@onready var play_button: Button = $MainContainer/RootVBox/FooterSection/PlayButton
@onready var tap_label: Label = $MainContainer/RootVBox/FooterSection/TapLabel

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	_play_intro_animation()

func _play_intro_animation() -> void:
	var tween_monster: Tween = create_tween()
	tween_monster.set_ease(Tween.EASE_IN_OUT)
	tween_monster.set_loops()
	tween_monster.tween_property(monster_image, "position:y", -158.0, 2.0)
	tween_monster.tween_property(monster_image, "position:y", -128.0, 2.0)
	
	var tween_button: Tween = create_tween()
	tween_button.set_ease(Tween.EASE_IN_OUT)
	tween_button.set_loops()
	play_button.scale = Vector2(0.95, 0.95)
	tween_button.tween_property(play_button, "scale", Vector2(1.0, 1.0), 1.5)
	tween_button.tween_property(play_button, "scale", Vector2(0.95, 0.95), 1.5)

func _on_play_pressed() -> void:
	GameState.go_to(GameState.Screen.MENU)
