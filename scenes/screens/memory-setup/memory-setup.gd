extends Control

@onready var theme_value: Label = $ScrollContainer/ContentVBox/LevelCard/LevelCardVBox/ThemeRow/ThemeInfo/ThemeValue
@onready var grid_value: Label = $ScrollContainer/ContentVBox/LevelCard/LevelCardVBox/StatsGrid/GridSizeCard/GridSizeVBox/GridSizeValue
@onready var diff_dot: ColorRect = $ScrollContainer/ContentVBox/LevelCard/LevelCardVBox/StatsGrid/DifficultyCard/DifficultyVBox/DiffHBox/DiffDot
@onready var diff_value: Label = $ScrollContainer/ContentVBox/LevelCard/LevelCardVBox/StatsGrid/DifficultyCard/DifficultyVBox/DiffHBox/DiffValue
@onready var bottom_nav: BottomNav = $BottomNav

# Face-down preview cards - pulse on click
@onready var face_down_cards: Array[PanelContainer] = [
	$ScrollContainer/ContentVBox/PreviewSection/BoardGridContainer/BoardGrid/PreviewCard2,
	$ScrollContainer/ContentVBox/PreviewSection/BoardGridContainer/BoardGrid/PreviewCard3,
]

func _ready() -> void:
	_populate_level_info()
	bottom_nav.start_pressed.connect(_on_start_pressed)
	for card in face_down_cards:
		card.gui_input.connect(_on_facedown_card_input.bind(card))
	_play_hero_fade_in()
	
	# Connect bottom nav buttons
	bottom_nav.tab_changed.connect(_on_tab_pressed)
	bottom_nav.set_active("play")

func _populate_level_info() -> void:
	theme_value.text = "Dinosaurs"
	grid_value.text = "2x2"
	diff_value.text = "Easy"
	diff_dot.color = Color(0.204, 0.831, 0.600, 1.0)

func _play_hero_fade_in() -> void:
	var hero = $ScrollContainer/ContentVBox/HeroSection
	hero.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(hero, "modulate:a", 1.0, 0.4).set_ease(Tween.EASE_OUT)

func _on_facedown_card_input(event: InputEvent, card: PanelContainer) -> void:
	if event is InputEventMouseButton and event.pressed:
		_pulse(card)

func _pulse(node: Control) -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "scale", Vector2(1.06, 1.06), 0.12)
	tween.tween_property(node, "scale", Vector2(1.0, 1.0), 0.12)

func _on_start_pressed() -> void:
	GameState.go_to(GameState.Screen.MEMORY)

func _on_tab_pressed(tab_name: String) -> void:
	bottom_nav.set_active(tab_name)
	match tab_name:
		"play":
			GameState.go_to(GameState.Screen.MENU)
		"merge":
			GameState.go_to(GameState.Screen.MERGE)
		"collection":
			GameState.go_to(GameState.Screen.COLLECTION)
		"shop":
			GameState.go_to(GameState.Screen.SHOP)
		"settings":
			GameState.go_to(GameState.Screen.SETTINGS)
