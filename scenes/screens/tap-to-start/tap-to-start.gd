extends Control

@onready var monster_image: TextureRect = $MainContainer/RootVBox/CenterSection/CreatureContainer/MonsterImage
@onready var play_button: Button = $MainContainer/RootVBox/FooterSection/PlayButton
@onready var tap_label: Label = $MainContainer/RootVBox/FooterSection/TapLabel

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)

	if has_node("/root/TutorialSystem"):
		var tutorial = get_node("/root/TutorialSystem")
		tutorial.register_node("tap_to_start_play_button", play_button)
		if not SaveSystem.get_data().get("progression", {}).get("tutorial_completed", false):
			tutorial.start_tutorial()

	_play_intro_animation()
	
	# Set all label font sizes to 24px
	tap_label.add_theme_font_size_override("font_size", 24)
	play_button.add_theme_font_size_override("font_size", 24)

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
	if has_node("/root/TutorialSystem") and get_node("/root/TutorialSystem").is_active:
		if get_node("/root/TutorialSystem").current_step == 0:
			# Advance tutorial so the highlight moves or clears
			get_node("/root/TutorialSystem").next_step()

	GameState.go_to(GameState.Screen.MENU)
