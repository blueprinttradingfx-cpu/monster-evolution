extends Control

@onready var main_vbox: VBoxContainer = $CenterContainer/MainVBox
@onready var logo: TextureRect = $CenterContainer/MainVBox/LogoSection/Logo
@onready var subtitle: Label = $CenterContainer/MainVBox/TitleSection/Subtitle
@onready var progress_bar: ProgressBar = $CenterContainer/MainVBox/LoadingSection/ProgressBar
@onready var status_label: Label = $CenterContainer/MainVBox/LoadingSection/StatusRow/StatusLabel

var is_loading = true
var progress: float = 0.0
var loading_text_index: int = 0
var loading_texts: Array[String] = [
	"Waking up the monsters...",
	"Polishing the eggs...",
	"Growing green grass...",
	"Shuffling the memory tiles...",
	"Almost ready to merge..."
]

func _ready() -> void:
	_play_intro_animation()
	_start_loading_simulation()
	await get_tree().create_timer(5.0).timeout
	is_loading = false
	GameState.go_to(GameState.Screen.TAP_TO_START)

func _play_intro_animation() -> void:
	main_vbox.modulate = Color(1,1,1,0)
	var tween_fade: Tween = create_tween()
	tween_fade.set_ease(Tween.EASE_OUT)
	tween_fade.tween_property(main_vbox, "modulate:a", 1.0, 0.5)
	
	var tween_logo: Tween = create_tween()
	tween_logo.set_ease(Tween.EASE_IN_OUT)
	tween_logo.tween_property(logo, "modulate:a", 0.95, 3.0).from(1.0)
	tween_logo.set_loops()

func _start_loading_simulation() -> void:
	await get_tree().create_timer(0.5).timeout
	while is_loading:
		await get_tree().create_timer(1.2).timeout
		_update_progress()
	
func _update_progress() -> void:
	if progress >= 1.0:
		return
	
	var increment: float = randf_range(0.03, 0.08)
	progress = min(progress + increment, 1.0)
	
	progress_bar.value = progress * 100.0
	
	if progress < 1.0:
		loading_text_index = (loading_text_index + 1) % loading_texts.size()
		status_label.text = loading_texts[loading_text_index]
	else:
		status_label.text = "Ready!"
